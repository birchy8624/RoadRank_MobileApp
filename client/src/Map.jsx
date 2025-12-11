import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Polyline, Popup, useMapEvents } from 'react-leaflet';
import axios from 'axios';
import RatingModal from './RatingModal';
import 'leaflet/dist/leaflet.css';
import './Map.css';

const center = [54.0, -2.0]; // [lat, lng] for Leaflet

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
        color: '#0000FF',
        opacity: 0.8,
        weight: 5,
      }}
    />
  ) : null;
}

function Map() {
  const [roads, setRoads] = useState([]);
  const [drawing, setDrawing] = useState(false);
  const [drawnPath, setDrawnPath] = useState([]);
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [selectedRoad, setSelectedRoad] = useState(null);

  useEffect(() => {
    fetchRoads();
  }, []);

  const fetchRoads = async () => {
    try {
      const response = await axios.get(`${import.meta.env.VITE_API_BASE_URL}/api/roads`);
      setRoads(Array.isArray(response.data) ? response.data : []);
    } catch (error) {
      console.error('Error fetching roads:', error);
      setRoads([]);
    }
  };

  const getRoadColor = (rating) => {
    if (rating >= 4) return '#00FF00'; // Green
    if (rating >= 2.5) return '#FFFF00'; // Yellow
    return '#FF0000'; // Red
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
    }
  };

  return (
    <>
      {showRatingModal && <RatingModal onSubmit={handleSubmitRating} onCancel={handleCancelRating} />}
      <div className="controls-container">
        {!drawing && (
          <button onClick={() => setDrawing(true)} className="control-button">
            Draw Route
          </button>
        )}
        {drawing && drawnPath.length > 0 && (
          <button onClick={handleSaveRoute} className="control-button save">
            Save Route
          </button>
        )}
      </div>
      <MapContainer
        center={center}
        zoom={6}
        className="map-container"
        style={{ cursor: drawing ? 'crosshair' : 'grab' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

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
                    <div>
                      <h3>Road Details</h3>
                      <p>Twistiness: {selectedRoad.twistiness}</p>
                      <p>Surface Condition: {selectedRoad.surface_condition}</p>
                      <p>Fun Factor: {selectedRoad.fun_factor}</p>
                      <p>Scenery: {selectedRoad.scenery}</p>
                      <p>Visibility: {selectedRoad.visibility}</p>
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
              color: '#0000FF',
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
