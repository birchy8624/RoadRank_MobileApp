import React, { useState, useEffect } from 'react';
import { GoogleMap, useJsApiLoader, Polyline, InfoWindow } from '@react-google-maps/api';
import axios from 'axios';
import RatingModal from './RatingModal';
import './Map.css';

const center = {
  lat: 54.0,
  lng: -2.0,
};

function Map() {
  const { isLoaded } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY,
    libraries: ['drawing'],
  });

  const [roads, setRoads] = useState([]);
  const [drawing, setDrawing] = useState(false);
  const [drawnPath, setDrawnPath] = useState([]);
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [selectedRoad, setSelectedRoad] = useState(null);

  useEffect(() => {
    async function fetchRoads() {
      try {
        const response = await axios.get(`${import.meta.env.VITE_API_BASE_URL}/api/roads`);
        setRoads(response.data);
      } catch (error) {
        console.error('Error fetching roads:', error);
      }
    }
    if (isLoaded) {
      fetchRoads();
    }
  }, [isLoaded]);

  if (!isLoaded) {
    return <div>Loading...</div>;
  }

  const getRoadColor = (rating) => {
    if (rating >= 4) return '#00FF00'; // Green
    if (rating >= 2.5) return '#FFFF00'; // Yellow
    return '#FF0000'; // Red
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
        path: drawnPath,
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
          <button onClick={handleSaveRoute} className="control-button">
            Save Route
          </button>
        )}
      </div>
      <GoogleMap
        mapContainerClassName="map-container"
        center={center}
        zoom={6}
        options={{
          disableDefaultUI: true,
          draggableCursor: drawing ? 'crosshair' : 'grab',
        }}
        onMouseDown={(e) => {
          if (drawing) {
            setDrawnPath([{ lat: e.latLng.lat(), lng: e.latLng.lng() }]);
          }
        }}
        onMouseMove={(e) => {
          if (drawing && drawnPath.length > 0) {
            setDrawnPath([...drawnPath, { lat: e.latLng.lat(), lng: e.latLng.lng() }]);
          }
        }}
        onMouseUp={async () => {
          if (drawing && drawnPath.length > 1) {
            const pathString = drawnPath.map((p) => `${p.lat},${p.lng}`).join('|');
            const response = await axios.get(
              `https://roads.googleapis.com/v1/snapToRoads?path=${pathString}&interpolate=true&key=${import.meta.env.VITE_GOOGLE_MAPS_API_KEY}`
            );
            const snappedPoints = response.data.snappedPoints.map((p) => ({
              lat: p.location.latitude,
              lng: p.location.longitude,
            }));
            setDrawnPath(snappedPoints);
          }
        }}
      >
        {roads.map((road) => (
          <Polyline
            key={road.id}
            path={JSON.parse(road.path)}
            options={{
              strokeColor: getRoadColor(road.fun_factor),
              strokeOpacity: 0.8,
              strokeWeight: 5,
            }}
            onClick={() => setSelectedRoad(road)}
          />
        ))}
        {selectedRoad && (() => {
          const path = JSON.parse(selectedRoad.path);
          const middleIndex = Math.floor(path.length / 2);
          return (
            <InfoWindow
              position={path[middleIndex]}
              onCloseClick={() => setSelectedRoad(null)}
            >
              <div>
                <h3>Road Details</h3>
                <p>Twistiness: {selectedRoad.twistiness}</p>
                <p>Surface Condition: {selectedRoad.surface_condition}</p>
                <p>Fun Factor: {selectedRoad.fun_factor}</p>
                <p>Scenery: {selectedRoad.scenery}</p>
                <p>Visibility: {selectedRoad.visibility}</p>
              </div>
            </InfoWindow>
          );
        })()}
            <div>
              <h3>Road Details</h3>
              <p>Twistiness: {selectedRoad.twistiness}</p>
              <p>Surface Condition: {selectedRoad.surface_condition}</p>
              <p>Fun Factor: {selectedRoad.fun_factor}</p>
              <p>Scenery: {selectedRoad.scenery}</p>
              <p>Visibility: {selectedRoad.visibility}</p>
            </div>
          </InfoWindow>
        )}
        {drawnPath.length > 0 && (
          <Polyline
            path={drawnPath}
            options={{
              strokeColor: '#0000FF',
              strokeOpacity: 0.8,
              strokeWeight: 5,
            }}
          />
        )}
      </GoogleMap>
    </>
  );
}

export default React.memo(Map);
