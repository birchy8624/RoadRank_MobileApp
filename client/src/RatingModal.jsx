import React, { useState } from 'react';
import './RatingModal.css';

const ratingLabels = {
  twistiness: { icon: '🌀', label: 'Twistiness' },
  surface_condition: { icon: '🛤️', label: 'Surface Condition' },
  fun_factor: { icon: '⚡', label: 'Fun Factor' },
  scenery: { icon: '🏞️', label: 'Scenery' },
  visibility: { icon: '👁️', label: 'Visibility' },
};

const ratingDescriptions = [
  'Poor',
  'Fair',
  'Good',
  'Great',
  'Excellent'
];

function RatingModal({ onSubmit, onCancel, roadName, showComment = false }) {
  const [ratings, setRatings] = useState({
    twistiness: 3,
    surface_condition: 3,
    fun_factor: 3,
    scenery: 3,
    visibility: 3,
  });

  const [comment, setComment] = useState('');

  const handleChange = (e) => {
    setRatings({ ...ratings, [e.target.name]: Number(e.target.value) });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      ...ratings,
      ...(showComment ? { comment } : {}),
    });
  };

  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal-container" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Rate {roadName || 'this road'}</h2>
          <p className="modal-subtitle">Share your experience with fellow riders</p>
        </div>

        <form onSubmit={handleSubmit} className="modal-form">
          <div className="rating-grid">
            {Object.entries(ratings).map(([key, value]) => (
              <div key={key} className="rating-item">
                <div className="rating-label">
                  <span className="rating-icon">{ratingLabels[key].icon}</span>
                  <span className="rating-name">{ratingLabels[key].label}</span>
                </div>

                <div className="rating-control">
                  <input
                    type="range"
                    name={key}
                    min="1"
                    max="5"
                    value={value}
                    onChange={handleChange}
                    className="rating-slider"
                    style={{
                      background: `linear-gradient(to right,
                        var(--accent-primary) 0%,
                        var(--accent-primary) ${((value - 1) / 4) * 100}%,
                        var(--border) ${((value - 1) / 4) * 100}%,
                        var(--border) 100%)`
                    }}
                  />

                  <div className="rating-value">
                    <span className="rating-number">{value}</span>
                    <span className="rating-description">{ratingDescriptions[value - 1]}</span>
                  </div>
                </div>

                <div className="rating-dots">
                  {[1, 2, 3, 4, 5].map((dot) => (
                    <div
                      key={dot}
                      className={`rating-dot ${value >= dot ? 'active' : ''}`}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>

          {showComment && (
            <div className="comment-field">
              <label htmlFor="comment">Add a short note</label>
              <textarea
                id="comment"
                name="comment"
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="What made this road special? Surface quality, scenery, traffic..."
              />
            </div>
          )}

          <div className="modal-actions">
            <button type="button" onClick={onCancel} className="button-secondary">
              Cancel
            </button>
            <button type="submit" className="button-primary">
              Submit Rating
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default RatingModal;
