import React, { useState, useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Polyline, Popup, useMapEvents, useMap } from 'react-leaflet';
import axios from 'axios';
import RatingModal from './RatingModal';
import 'leaflet/dist/leaflet.css';
import './Map.css';

const center = [54.0, -2.0]; // [lat, lng] for Leaflet

// 10 Preloaded fake roads with realistic UK routes and ratings
const FAKE_ROADS = [
  {
    id: 'fake-1',
    name: 'Snake Pass (A57)',
    path: [
      { lat: 53.4040, lng: -1.8186 },
      { lat: 53.4050, lng: -1.8300 },
      { lat: 53.4070, lng: -1.8450 },
      { lat: 53.4100, lng: -1.8600 },
      { lat: 53.4120, lng: -1.8750 },
    ],
    twistiness: 5,
    surface_condition: 3,
    fun_factor: 5,
    scenery: 5,
    visibility: 4,
  },
  {
    id: 'fake-2',
    name: 'Cat and Fiddle (A537)',
    path: [
      { lat: 53.2650, lng: -2.0200 },
      { lat: 53.2700, lng: -2.0100 },
      { lat: 53.2750, lng: -2.0000 },
      { lat: 53.2800, lng: -1.9900 },
    ],
    twistiness: 4,
    surface_condition: 4,
    fun_factor: 5,
    scenery: 5,
    visibility: 3,
  },
  {
    id: 'fake-3',
    name: 'Hardknott Pass',
    path: [
      { lat: 54.4010, lng: -3.2100 },
      { lat: 54.4050, lng: -3.2000 },
      { lat: 54.4090, lng: -3.1900 },
      { lat: 54.4120, lng: -3.1800 },
    ],
    twistiness: 5,
    surface_condition: 2,
    fun_factor: 4,
    scenery: 5,
    visibility: 4,
  },
  {
    id: 'fake-4',
    name: 'Bealach na Bà',
    path: [
      { lat: 57.3800, lng: -5.7500 },
      { lat: 57.3850, lng: -5.7400 },
      { lat: 57.3900, lng: -5.7300 },
      { lat: 57.3950, lng: -5.7200 },
      { lat: 57.4000, lng: -5.7100 },
    ],
    twistiness: 5,
    surface_condition: 3,
    fun_factor: 5,
    scenery: 5,
    visibility: 3,
  },
  {
    id: 'fake-5',
    name: 'Buttertubs Pass (B6270)',
    path: [
      { lat: 54.3600, lng: -2.1800 },
      { lat: 54.3650, lng: -2.1700 },
      { lat: 54.3700, lng: -2.1600 },
      { lat: 54.3750, lng: -2.1500 },
    ],
    twistiness: 4,
    surface_condition: 4,
    fun_factor: 4,
    scenery: 5,
    visibility: 4,
  },
  {
    id: 'fake-6',
    name: 'Loch Ness Scenic Route',
    path: [
      { lat: 57.3200, lng: -4.4200 },
      { lat: 57.3100, lng: -4.4100 },
      { lat: 57.3000, lng: -4.4000 },
      { lat: 57.2900, lng: -4.3900 },
    ],
    twistiness: 3,
    surface_condition: 5,
    fun_factor: 4,
    scenery: 5,
    visibility: 5,
  },
  {
    id: 'fake-7',
    name: 'Wrynose Pass',
    path: [
      { lat: 54.4300, lng: -3.1100 },
      { lat: 54.4350, lng: -3.1000 },
      { lat: 54.4400, lng: -3.0900 },
      { lat: 54.4450, lng: -3.0800 },
    ],
    twistiness: 5,
    surface_condition: 3,
    fun_factor: 4,
    scenery: 4,
    visibility: 3,
  },
  {
    id: 'fake-8',
    name: 'Cairngorms Pass (A939)',
    path: [
      { lat: 57.2200, lng: -3.3200 },
      { lat: 57.2250, lng: -3.3100 },
      { lat: 57.2300, lng: -3.3000 },
      { lat: 57.2350, lng: -3.2900 },
      { lat: 57.2400, lng: -3.2800 },
    ],
    twistiness: 3,
    surface_condition: 4,
    fun_factor: 3,
    scenery: 5,
    visibility: 4,
  },
  {
    id: 'fake-9',
    name: 'Rest and Be Thankful (A83)',
    path: [
      { lat: 56.2300, lng: -4.7500 },
      { lat: 56.2350, lng: -4.7400 },
      { lat: 56.2400, lng: -4.7300 },
      { lat: 56.2450, lng: -4.7200 },
    ],
    twistiness: 4,
    surface_condition: 4,
    fun_factor: 4,
    scenery: 5,
    visibility: 4,
  },
  {
    id: 'fake-10',
    name: 'Evo Triangle (B4391/B5105/A543)',
    path: [
      { lat: 53.0900, lng: -3.5200 },
      { lat: 53.0950, lng: -3.5100 },
      { lat: 53.1000, lng: -3.5000 },
      { lat: 53.1050, lng: -3.4900 },
      { lat: 53.1100, lng: -3.4800 },
    ],
    twistiness: 5,
    surface_condition: 4,
    fun_factor: 5,
    scenery: 4,
    visibility: 4,
  },
];

// Component to disable dragging when in draw mode
function MapController({ drawing }) {
  const map = useMap();

  useEffect(() => {
    if (drawing) {
      map.dragging.disable();
    } else {
      map.dragging.enable();
    }
  }, [drawing, map]);

  return null;
}

// Component for drawing roads
function DrawingLayer({ drawing, onDraw }) {
  const [currentPath, setCurrentPath] = useState([]);
  const [isDrawing, setIsDrawing] = useState(false);

  useMapEvents({
    mousedown: (e) => {
      if (drawing) {
        setIsDrawing(true);
        const newPoint = [e.latlng.lat, e.latlng.lng];
        setCurrentPath([newPoint]);
      }
    },
    mousemove: (e) => {
      if (drawing && isDrawing) {
        const newPoint = [e.latlng.lat, e.latlng.lng];
        setCurrentPath((prev) => [...prev, newPoint]);
      }
    },
    mouseup: () => {
      if (drawing && isDrawing) {
        setIsDrawing(false);
        onDraw(currentPath);
        setCurrentPath([]);
      }
    },
  });

  return currentPath.length > 0 ? (
    <Polyline
      positions={currentPath}
      pathOptions={{
        color: '#0ea5e9',
        opacity: 0.8,
        weight: 5,
      }}
    />
  ) : null;
}

// Search component
function SearchBox({ onLocationFound }) {
  const [query, setQuery] = useState('');
  const [searching, setSearching] = useState(false);
  const [results, setResults] = useState([]);
  const [showResults, setShowResults] = useState(false);

  const handleSearch = async (searchQuery) => {
    if (!searchQuery.trim()) {
      setResults([]);
      return;
    }

    setSearching(true);
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=5`
      );
      const data = await response.json();
      setResults(data);
      setShowResults(true);
    } catch (error) {
      console.error('Search error:', error);
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
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [selectedRoad, setSelectedRoad] = useState(null);
  const mapRef = useRef(null);

  useEffect(() => {
    fetchRoads();
  }, []);

  const fetchRoads = async () => {
    try {
      const response = await axios.get(`${import.meta.env.VITE_API_BASE_URL}/api/roads`);
      const apiRoads = Array.isArray(response.data) ? response.data : [];
      // Combine fake roads with API roads
      setRoads([...FAKE_ROADS, ...apiRoads]);
    } catch (error) {
      console.error('Error fetching roads:', error);
      // If API fails, just show fake roads
      setRoads(FAKE_ROADS);
    }
  };

  const getRoadColor = (rating) => {
    if (rating >= 4) return '#10b981'; // Green
    if (rating >= 2.5) return '#f59e0b'; // Orange/Yellow
    return '#ef4444'; // Red
  };

  const handleDrawComplete = (path) => {
    if (path.length > 1) {
      setDrawnPath(path);
    }
  };

  const handleSaveRoute = () => {
    setDrawing(false);
    setShowRatingModal(true);
  };

  const handleCancelRating = () => {
    setShowRatingModal(false);
    setDrawnPath([]);
  };

  const handleSubmitRating = async (ratings) => {
    try {
      const newRoad = {
        path: drawnPath.map(([lat, lng]) => ({ lat, lng })),
        ...ratings,
      };
      const response = await axios.post(`${import.meta.env.VITE_API_BASE_URL}/api/roads`, newRoad);
      setRoads([...roads, response.data]);
      setShowRatingModal(false);
      setDrawnPath([]);
    } catch (error) {
      console.error('Error saving road:', error);
      // Still add it locally even if save fails
      const localRoad = {
        id: `local-${Date.now()}`,
        path: JSON.stringify(drawnPath.map(([lat, lng]) => ({ lat, lng }))),
        ...ratings,
      };
      setRoads([...roads, localRoad]);
      setShowRatingModal(false);
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

  return (
    <>
      {showRatingModal && <RatingModal onSubmit={handleSubmitRating} onCancel={handleCancelRating} />}

      <SearchBox onLocationFound={handleLocationFound} />

      <div className="info-panel">
        <div className="info-panel__header">
          <p className="eyebrow">Experience kit</p>
          <h3>Map-first ride builder</h3>
        </div>
        <p>
          Search for destinations, draw custom lines, and rate every road with our refreshed glass UI
          library.
        </p>
        <ul>
          <li>Fly-to search with location previews</li>
          <li>Draw, save, and instantly open the rating modal</li>
          <li>Tap any polyline to view the full rating breakdown</li>
        </ul>
      </div>

      <div className="controls-container">
        {!drawing && (
          <button onClick={() => setDrawing(true)} className="control-button">
            ✏️ Draw Route
          </button>
        )}
        {drawing && (
          <>
            {drawnPath.length > 0 && (
              <button onClick={handleSaveRoute} className="control-button save">
                ✓ Save Route
              </button>
            )}
            <button onClick={() => { setDrawing(false); setDrawnPath([]); }} className="control-button cancel">
              ✕ Cancel
            </button>
          </>
        )}
      </div>

      <MapContainer
        ref={mapRef}
        center={center}
        zoom={6}
        className="map-container"
        style={{ cursor: drawing ? 'crosshair' : 'grab' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapController drawing={drawing} />
        <DrawingLayer drawing={drawing} onDraw={handleDrawComplete} />

        {roads.map((road) => {
          try {
            const path = typeof road.path === 'string' ? JSON.parse(road.path) : road.path;
            if (!Array.isArray(path)) return null;

            const positions = path.map((p) => [p.lat, p.lng]);
            const middleIndex = Math.floor(positions.length / 2);

            return (
              <Polyline
                key={road.id}
                positions={positions}
                pathOptions={{
                  color: getRoadColor(road.fun_factor),
                  opacity: 0.8,
                  weight: 5,
                }}
                eventHandlers={{
                  click: () => setSelectedRoad({ ...road, middlePosition: positions[middleIndex] }),
                }}
              >
                {selectedRoad && selectedRoad.id === road.id && (
                  <Popup
                    position={selectedRoad.middlePosition}
                    onClose={() => setSelectedRoad(null)}
                  >
                    <div className="popup-content">
                      {selectedRoad.name && <h3 className="popup-title">{selectedRoad.name}</h3>}
                      {!selectedRoad.name && <h3 className="popup-title">Road Details</h3>}
                      <div className="popup-ratings">
                        <div className="popup-rating-item">
                          <span className="rating-label">🌀 Twistiness</span>
                          <span className="rating-value">{selectedRoad.twistiness}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">🛤️ Surface</span>
                          <span className="rating-value">{selectedRoad.surface_condition}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">⚡ Fun Factor</span>
                          <span className="rating-value">{selectedRoad.fun_factor}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">🏞️ Scenery</span>
                          <span className="rating-value">{selectedRoad.scenery}/5</span>
                        </div>
                        <div className="popup-rating-item">
                          <span className="rating-label">👁️ Visibility</span>
                          <span className="rating-value">{selectedRoad.visibility}/5</span>
                        </div>
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
