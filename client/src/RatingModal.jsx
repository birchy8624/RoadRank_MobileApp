import React, { useState } from 'react';

const modalStyle = {
  position: 'fixed',
  top: '50%',
  left: '50%',
  transform: 'translate(-50%, -50%)',
  backgroundColor: 'white',
  padding: '20px',
  borderRadius: '8px',
  zIndex: 1000,
  boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
};

const overlayStyle = {
  position: 'fixed',
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  backgroundColor: 'rgba(0, 0, 0, 0.5)',
  zIndex: 999,
};

function RatingModal({ onSubmit, onCancel }) {
  const [ratings, setRatings] = useState({
    twistiness: 3,
    surface_condition: 3,
    fun_factor: 3,
    scenery: 3,
    visibility: 3,
  });

  const handleChange = (e) => {
    setRatings({ ...ratings, [e.target.name]: Number(e.target.value) });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(ratings);
  };

  return (
    <>
      <div style={overlayStyle} onClick={onCancel} />
      <div style={modalStyle}>
        <h2>Rate this Road</h2>
        <form onSubmit={handleSubmit}>
          <div>
            <label>Twistiness: {ratings.twistiness}</label>
            <input type="range" name="twistiness" min="1" max="5" value={ratings.twistiness} onChange={handleChange} />
          </div>
          <div>
            <label>Surface Condition: {ratings.surface_condition}</label>
            <input type="range" name="surface_condition" min="1" max="5" value={ratings.surface_condition} onChange={handleChange} />
          </div>
          <div>
            <label>Fun Factor: {ratings.fun_factor}</label>
            <input type="range" name="fun_factor" min="1" max="5" value={ratings.fun_factor} onChange={handleChange} />
          </div>
          <div>
            <label>Scenery: {ratings.scenery}</label>
            <input type="range" name="scenery" min="1" max="5" value={ratings.scenery} onChange={handleChange} />
          </div>
          <div>
            <label>Visibility: {ratings.visibility}</label>
            <input type="range" name="visibility" min="1" max="5" value={ratings.visibility} onChange={handleChange} />
          </div>
          <button type="submit">Submit Rating</button>
          <button type="button" onClick={onCancel}>Cancel</button>
        </form>
      </div>
    </>
  );
}

export default RatingModal;
