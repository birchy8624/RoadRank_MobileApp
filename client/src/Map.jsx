import React, { useState, useEffect, useRef, useMemo } from 'react';
import { MapContainer, TileLayer, Polyline, Popup, Tooltip, useMapEvents, useMap, ZoomControl } from 'react-leaflet';
import axios from 'axios';
import RatingModal from './RatingModal';
import 'leaflet/dist/leaflet.css';
import './Map.css';
import logo from './assets/roadrank-logo.svg';

const center = [54.0, -2.0]; // [lat, lng] for Leaflet

// Component to disable dragging when in draw mode
function MapController({ drawing }) {
  const map = useMap();

  useEffect(() => {
    if (drawing) {
      map.dragging.disable();
      map.touchZoom.disable();
      map.doubleClickZoom.disable();
      map.boxZoom.disable();
      map.keyboard.disable();
      if (map.tap) map.tap.disable();
    } else {
      map.dragging.enable();
      map.touchZoom.enable();
      map.doubleClickZoom.enable();
      map.boxZoom.enable();
      map.keyboard.enable();
      if (map.tap) map.tap.enable();
    }
  }, [drawing, map]);

  return null;
}

// Component for drawing roads
function DrawingLayer({ drawing, onDraw }) {
  const [currentPath, setCurrentPath] = useState([]);
  const [isDrawing, setIsDrawing] = useState(false);

  const startDrawing = (latlng) => {
    const newPoint = [latlng.lat, latlng.lng];
    setIsDrawing(true);
    setCurrentPath([newPoint]);
  };

  const continueDrawing = (latlng) => {
    const newPoint = [latlng.lat, latlng.lng];
    setCurrentPath((prev) => [...prev, newPoint]);
  };

  const endDrawing = () => {
    if (drawing && isDrawing) {
      onDraw(currentPath);
      setIsDrawing(false);
      setCurrentPath([]);
    }
  };

  useMapEvents({
    mousedown: (e) => {
      if (drawing) {
        startDrawing(e.latlng);
      }
    },
    mousemove: (e) => {
      if (drawing && isDrawing) {
        continueDrawing(e.latlng);
      }
    },
    mouseup: () => {
      endDrawing();
    },
    touchstart: (e) => {
      if (drawing) {
        e.originalEvent?.preventDefault();
        startDrawing(e.latlng);
      }
    },
    touchmove: (e) => {
      if (drawing && isDrawing) {
        e.originalEvent?.preventDefault();
        continueDrawing(e.latlng);
      }
    },
    touchend: () => {
      endDrawing();
    },
  });

  return currentPath.length > 0 ? (
    <Polyline
      positions={currentPath}
      pathOptions={{ color: '#3b82f6', weight: 5, opacity: 0.8 }}
    />
  ) : null;
}

// Search box component with Nominatim API
function SearchBox({ onLocationFound }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [showResults, setShowResults] = useState(false);
  const [searching, setSearching] = useState(false);

  const handleSearch = async (value) => {
    setSearching(true);
    try {
      const response = await axios.get('https://nominatim.openstreetmap.org/search', {
        params: { q: value, format: 'json', addressdetails: 1, limit: 5 },
      });
      setResults(response.data);
    } catch (error) {
      console.error('Error searching locations:', error);
    } finally {
      setSearching(false);
    }
  };

  const handleInputChange = (e) => {
    const value = e.target.value;
    setQuery(value);
    if (value.length > 2) {
      handleSearch(value);
    } else {
      setResults([]);
    }
  };

  const handleResultClick = (result) => {
    onLocationFound({
      lat: parseFloat(result.lat),
      lng: parseFloat(result.lon),
      name: result.display_name,
    });
    setQuery('');
    setResults([]);
    setShowResults(false);
  };

  return (
    <div className="search-container">
      <div className="search-input-wrapper">
        <span className="search-icon">🔍</span>
        <input
          type="text"
          value={query}
          onChange={handleInputChange}
          onFocus={() => setShowResults(true)}
          placeholder="Search for an address..."
          className="search-input"
        />
        {searching && <span className="search-loading">...</span>}
      </div>
      {showResults && results.length > 0 && (
        <>
          <div className="search-overlay" onClick={() => setShowResults(false)} />
          <div className="search-results">
            {results.map((result, index) => (
              <div
                key={index}
                className="search-result-item"
                onClick={() => handleResultClick(result)}
              >
                <span className="result-icon">📍</span>
                <span className="result-text">{result.display_name}</span>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

function Map() {
  const [roads, setRoads] = useState([]);
  const [drawing, setDrawing] = useState(false);
  const [drawnPath, setDrawnPath] = useState([]);
  const [ratingContext, setRatingContext] = useState(null);
  const [showDrawInstructions, setShowDrawInstructions] = useState(false);
  const [selectedRoad, setSelectedRoad] = useState(null);
  const [selectedRoadDetails, setSelectedRoadDetails] = useState({ ratings: [], summary: null, loading: false });
  const mapRef = useRef(null);

  const apiBase = useMemo(() => import.meta.env.VITE_API_BASE_URL || '', []);

  useEffect(() => {
    fetchRoads();
  }, []);

  const fetchRoads = async () => {
    try {
      const response = await axios.get(`${apiBase}/api/roads`);
      const apiRoads = Array.isArray(response.data) ? response.data : [];
      setRoads(apiRoads);
    } catch (error) {
      console.error('Error fetching roads:', error);
      setRoads([]);
    }
  };

  const getRoadColor = (rating) => {
    if (rating >= 4) return '#10b981'; // Green
    if (rating >= 2.5) return '#f59e0b'; // Orange/Yellow
    return '#ef4444'; // Red
  };

  const getRoadDisplayRating = (road) => road?.rating_summary?.avg_fun_factor || road?.fun_factor || 0;

  const handleDrawComplete = (path) => {
    if (path.length > 1) {
      setDrawnPath(path);
    }
  };

  const handleSaveRoute = () => {
    setDrawing(false);
    setRatingContext({ type: 'new', path: drawnPath });
  };

  const handleCancelRating = () => {
    setRatingContext(null);
    setDrawnPath([]);
  };

  const handleSubmitRating = async (ratings) => {
    try {
      if (ratingContext?.type === 'existing') {
        await axios.post(`${apiBase}/api/roads/${ratingContext.roadId}/ratings`, ratings);
        await fetchSelectedRoadRatings(ratingContext.roadId);
        setRatingContext(null);
        return;
      }

      const newRoad = {
        path: drawnPath.map(([lat, lng]) => ({ lat, lng })),
        ...ratings,
      };
      const response = await axios.post(`${apiBase}/api/roads`, newRoad);
      setRoads([...roads, response.data]);
      setRatingContext(null);
      setDrawnPath([]);
    } catch (error) {
      console.error('Error saving road:', error);
      // Still add it locally even if save fails
      const localRoad = {
        id: `local-${Date.now()}`,
        path: JSON.stringify(drawnPath.map(([lat, lng]) => ({ lat, lng }))),
        ...ratings,
        created_at: new Date().toISOString(),
      };
      setRoads([...roads, localRoad]);
      setRatingContext(null);
      setDrawnPath([]);
    }
  };

  const handleLocationFound = (location) => {
    if (mapRef.current) {
      mapRef.current.flyTo([location.lat, location.lng], 13, {
        duration: 2,
      });
    }
  };

  const handleOpenDrawInstructions = () => {
    setSelectedRoad(null);
    setShowDrawInstructions(true);
  };

  const handleStartDrawing = () => {
    setShowDrawInstructions(false);
    setDrawing(true);
  };

  const handleCloseInstructions = () => {
    setShowDrawInstructions(false);
  };

  const fetchSelectedRoadRatings = async (roadId) => {
    setSelectedRoadDetails((prev) => ({ ...prev, loading: true }));
    try {
      const response = await axios.get(`${apiBase}/api/roads/${roadId}/ratings`);
      setSelectedRoadDetails({
        ratings: response.data.ratings || [],
        summary: response.data.summary,
        loading: false,
      });
    } catch (error) {
      console.error('Error fetching road ratings:', error);
      setSelectedRoadDetails({ ratings: [], summary: null, loading: false });
    }
  };

  const openRatingModal = (road) => {
    setRatingContext({
      type: 'existing',
      roadId: road.id,
      roadName: road.name,
      summary: road.rating_summary || null
    });
  };

  const handleRoadSelect = (road, positions) => {
    const middleIndex = Math.floor(positions.length / 2);
    setSelectedRoad({ ...road, middlePosition: positions[middleIndex] });
    setSelectedRoadDetails({ ratings: [], summary: road.rating_summary || null, loading: true });
    fetchSelectedRoadRatings(road.id);
    openRatingModal(road);
  };

  const formatDate = (value) => {
    if (!value) return 'Unknown';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return 'Unknown';
    return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
  };

  const selectedSummary = useMemo(() => {
    if (!selectedRoad) return null;
    const fallback = {
      avg_twistiness: selectedRoad.twistiness || null,
      avg_surface_condition: selectedRoad.surface_condition || null,
      avg_fun_factor: selectedRoad.fun_factor || null,
      avg_scenery: selectedRoad.scenery || null,
      avg_visibility: selectedRoad.visibility || null,
      avg_overall:
        selectedRoad.twistiness && selectedRoad.surface_condition && selectedRoad.fun_factor &&
        selectedRoad.scenery && selectedRoad.visibility
          ? (
            selectedRoad.twistiness +
            selectedRoad.surface_condition +
            selectedRoad.fun_factor +
            selectedRoad.scenery +
            selectedRoad.visibility
          ) / 5
          : null,
      rating_count: selectedRoad.rating_summary?.rating_count || (selectedRoad.twistiness ? 1 : 0),
    };

    return selectedRoadDetails.summary || selectedRoad.rating_summary || fallback;
  }, [selectedRoad, selectedRoadDetails.summary]);

  return (
    <>
      {ratingContext && (
        <RatingModal
          onSubmit={handleSubmitRating}
          onCancel={handleCancelRating}
          roadName={ratingContext.roadName}
          showComment={true}
          isNewRoad={ratingContext.type === 'new'}
          roadDetails={ratingContext.type === 'existing' ? {
            summary: selectedRoadDetails.summary || ratingContext.summary,
            ratings: selectedRoadDetails.ratings,
            loading: selectedRoadDetails.loading
          } : null}
        />
      )}

      {showDrawInstructions && (
        <div className="draw-overlay" onClick={handleCloseInstructions}>
          <div className="draw-modal" onClick={(e) => e.stopPropagation()}>
            <div className="draw-modal-header">
              <div className="draw-modal-badge">✏️</div>
              <div>
                <h2>Draw your route</h2>
                <p>Follow these quick tips before you start tracing.</p>
              </div>
            </div>

            <ol className="draw-steps">
              <li>
                <span className="step-number">1</span>
                Move the map to the road you want to trace.
              </li>
              <li>
                <span className="step-number">2</span>
                Tap or click once to start, then trace along the road with your finger or mouse.
              </li>
              <li>
                <span className="step-number">3</span>
                Lift up to finish, then hit Save to rate your road.
              </li>
            </ol>

            <div className="draw-modal-actions">
              <button className="ghost" onClick={handleCloseInstructions}>
                Cancel
              </button>
              <button onClick={handleStartDrawing}>Start Drawing</button>
            </div>
          </div>
        </div>
      )}

      <div className="map-topbar">
        <div className="brand-chip">
          <img src={logo} alt="RoadRank" />
          <span>RoadRank</span>
        </div>

        <div className="topbar-search">
          <SearchBox onLocationFound={handleLocationFound} />
        </div>

        <div className="topbar-actions">
          {!drawing && (
            <button onClick={handleOpenDrawInstructions}>
              ✏️ Draw
            </button>
          )}
          {drawing && (
            <>
              {drawnPath.length > 0 && (
                <button className="secondary" onClick={handleSaveRoute}>
                  ✓ Save
                </button>
              )}
              <button className="destructive" onClick={() => { setDrawing(false); setDrawnPath([]); }}>
                ✕ Cancel
              </button>
            </>
          )}
        </div>
      </div>

      <MapContainer
        ref={mapRef}
        center={center}
        zoom={6}
        className={`map-container ${drawing ? 'drawing' : ''}`}
        zoomControl={false}
        style={{ cursor: drawing ? 'crosshair' : 'grab' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <ZoomControl position="bottomright" />

        <MapController drawing={drawing} />
        <DrawingLayer drawing={drawing} onDraw={handleDrawComplete} />

        {roads.map((road) => {
          try {
            const path = typeof road.path === 'string' ? JSON.parse(road.path) : road.path;
            if (!Array.isArray(path)) return null;

            const positions = path.map((p) => [p.lat, p.lng]);
            const roadName = road.name || 'Unnamed road';

            return (
              <Polyline
                key={road.id}
                positions={positions}
                pathOptions={{
                  color: getRoadColor(getRoadDisplayRating(road)),
                  opacity: 0.8,
                  weight: 5,
                }}
                eventHandlers={{
                  click: () => handleRoadSelect({ ...road, path }, positions),
                }}
              >
                <Tooltip className="road-tooltip" sticky>
                  {roadName}
                </Tooltip>
                {selectedRoad && selectedRoad.id === road.id && (
                  <Popup
                    position={selectedRoad.middlePosition}
                    onClose={() => setSelectedRoad(null)}
                  >
                    <div className="popup-content">
                      {selectedRoad.name && <h3 className="popup-title">{selectedRoad.name}</h3>}
                      {!selectedRoad.name && <h3 className="popup-title">Road Details</h3>}

                      <div className="popup-meta">
                        <span className="pill">Added {formatDate(selectedRoad.created_at)}</span>
                        <span className="pill neutral">
                          {selectedSummary?.avg_overall ? `${selectedSummary.avg_overall.toFixed(1)}/5 avg` : 'No ratings yet'}
                          {selectedSummary?.rating_count ? ` · ${selectedSummary.rating_count} ratings` : ''}
                        </span>
                      </div>

                      <div className="popup-ratings-grid">
                        <div className="popup-rating-item">
                          <span className="rating-label">🌀 Twistiness</span>
                          <span className="rating-value">{selectedSummary?.avg_twistiness?.toFixed(1) || '—'}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">🛤️ Surface</span>
                          <span className="rating-value">{selectedSummary?.avg_surface_condition?.toFixed(1) || '—'}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">⚡ Fun Factor</span>
                          <span className="rating-value">{selectedSummary?.avg_fun_factor?.toFixed(1) || '—'}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">🏞️ Scenery</span>
                          <span className="rating-value">{selectedSummary?.avg_scenery?.toFixed(1) || '—'}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">👁️ Visibility</span>
                          <span className="rating-value">{selectedSummary?.avg_visibility?.toFixed(1) || '—'}/5</span>
                        </div>
                      </div>

                      <div className="popup-actions">
                        <button
                          className="secondary"
                          onClick={() => openRatingModal(selectedRoad)}
                        >
                          Add your rating
                        </button>
                      </div>

                      <div className="popup-comments">
                        <div className="popup-comments-header">
                          <h4>Community feedback</h4>
                          {selectedRoadDetails.loading && <span className="chip">Loading…</span>}
                        </div>
                        {selectedRoadDetails.ratings.length === 0 && !selectedRoadDetails.loading && (
                          <p className="muted">No ratings yet. Be the first to share your take.</p>
                        )}
                        {selectedRoadDetails.ratings.map((rating) => (
                          <div key={rating.id} className="comment-card">
                            <div className="comment-meta">
                              <span className="comment-date">{formatDate(rating.created_at)}</span>
                              <span className="comment-score">{(((rating.twistiness + rating.surface_condition + rating.fun_factor + rating.scenery + rating.visibility) / 5) || 0).toFixed(1)}/5</span>
                            </div>
                            {rating.comment && <p className="comment-body">{rating.comment}</p>}
                          </div>
                        ))}
                      </div>
                    </div>
                  </Popup>
                )}
              </Polyline>
            );
          } catch (err) {
            console.error('Error rendering road:', road, err);
            return null;
          }
        })}

        {drawnPath.length > 0 && (
          <Polyline
            positions={drawnPath}
            pathOptions={{
              color: '#0ea5e9',
              opacity: 0.8,
              weight: 5,
            }}
          />
        )}
      </MapContainer>
    </>
  );
}

export default React.memo(Map);
