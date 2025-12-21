import React, { useState, useMemo } from 'react';
import './RatingModal.css';

const COMMENTS_PREVIEW_COUNT = 2;

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

function RatingModal({
  onSubmit,
  onCancel,
  roadName,
  showComment = false,
  isNewRoad = false,
  roadDetails = null // { summary, ratings, loading }
}) {
  // For existing roads, start in 'details' view; for new roads, start in 'rate' view
  const [viewMode, setViewMode] = useState(isNewRoad ? 'rate' : 'details');

  const [ratings, setRatings] = useState({
    twistiness: 3,
    surface_condition: 3,
    fun_factor: 3,
    scenery: 3,
    visibility: 3,
  });

  const [comment, setComment] = useState('');
  const [name, setName] = useState('');
  const [commentsExpanded, setCommentsExpanded] = useState(false);

  const handleChange = (e) => {
    setRatings({ ...ratings, [e.target.name]: Number(e.target.value) });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      ...ratings,
      ...(showComment ? { comment } : {}),
      ...(isNewRoad ? { name: name.trim() || null } : {}),
    });
  };

  const formatDate = (value) => {
    if (!value) return 'Unknown';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return 'Unknown';
    return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
  };

  const summary = roadDetails?.summary;
  const existingRatings = roadDetails?.ratings || [];
  const loading = roadDetails?.loading || false;

  // Calculate which comments to display based on expanded state
  const visibleComments = useMemo(() => {
    if (commentsExpanded || existingRatings.length <= COMMENTS_PREVIEW_COUNT) {
      return existingRatings;
    }
    return existingRatings.slice(0, COMMENTS_PREVIEW_COUNT);
  }, [existingRatings, commentsExpanded]);

  const hiddenCommentsCount = existingRatings.length - COMMENTS_PREVIEW_COUNT;
  const hasMoreComments = existingRatings.length > COMMENTS_PREVIEW_COUNT;

  // Details view for existing roads
  if (viewMode === 'details' && !isNewRoad) {
    return (
      <div className="modal-overlay" onClick={onCancel}>
        <div className="modal-container" onClick={(e) => e.stopPropagation()}>
          <div className="modal-header">
            <h2>{roadName || 'Road Details'}</h2>
            <p className="modal-subtitle">
              {summary?.rating_count
                ? `${summary.rating_count} rating${summary.rating_count !== 1 ? 's' : ''} from the community`
                : 'No ratings yet'}
            </p>
          </div>

          {/* Average Ratings Section */}
          <div className="details-section">
            <h3 className="details-section-title">Average Ratings</h3>
            {summary?.avg_overall ? (
              <>
                <div className="overall-rating">
                  <span className="overall-score">{summary.avg_overall.toFixed(1)}</span>
                  <span className="overall-label">/ 5 overall</span>
                </div>
                <div className="details-ratings-grid">
                  <div className="details-rating-item">
                    <span className="details-rating-icon">🌀</span>
                    <span className="details-rating-label">Twistiness</span>
                    <span className="details-rating-value">{summary.avg_twistiness?.toFixed(1) || '—'}</span>
                  </div>
                  <div className="details-rating-item">
                    <span className="details-rating-icon">🛤️</span>
                    <span className="details-rating-label">Surface</span>
                    <span className="details-rating-value">{summary.avg_surface_condition?.toFixed(1) || '—'}</span>
                  </div>
                  <div className="details-rating-item">
                    <span className="details-rating-icon">⚡</span>
                    <span className="details-rating-label">Fun Factor</span>
                    <span className="details-rating-value">{summary.avg_fun_factor?.toFixed(1) || '—'}</span>
                  </div>
                  <div className="details-rating-item">
                    <span className="details-rating-icon">🏞️</span>
                    <span className="details-rating-label">Scenery</span>
                    <span className="details-rating-value">{summary.avg_scenery?.toFixed(1) || '—'}</span>
                  </div>
                  <div className="details-rating-item">
                    <span className="details-rating-icon">👁️</span>
                    <span className="details-rating-label">Visibility</span>
                    <span className="details-rating-value">{summary.avg_visibility?.toFixed(1) || '—'}</span>
                  </div>
                </div>
              </>
            ) : (
              <p className="no-ratings-message">No ratings yet. Be the first to rate this road!</p>
            )}
          </div>

          {/* Comments Section */}
          <div className="details-section">
            <div
              className={`details-section-header ${hasMoreComments ? 'clickable' : ''}`}
              onClick={hasMoreComments ? () => setCommentsExpanded(!commentsExpanded) : undefined}
            >
              <h3 className="details-section-title">
                Comments
                {existingRatings.length > 0 && (
                  <span className="comments-count">{existingRatings.length}</span>
                )}
                {loading && <span className="loading-indicator">Loading...</span>}
              </h3>
              {hasMoreComments && (
                <button
                  type="button"
                  className="expand-toggle"
                  onClick={(e) => {
                    e.stopPropagation();
                    setCommentsExpanded(!commentsExpanded);
                  }}
                >
                  {commentsExpanded ? 'Show less' : `See all ${existingRatings.length}`}
                  <span className={`expand-icon ${commentsExpanded ? 'expanded' : ''}`}>
                    &#9660;
                  </span>
                </button>
              )}
            </div>
            <div className={`details-comments-list ${commentsExpanded ? 'expanded' : ''}`}>
              {!loading && existingRatings.length === 0 && (
                <p className="no-comments-message">No comments yet. Share your experience!</p>
              )}
              {visibleComments.map((rating) => (
                <div key={rating.id} className="details-comment-card">
                  <div className="details-comment-header">
                    <span className="details-comment-date">{formatDate(rating.created_at)}</span>
                    <span className="details-comment-score">
                      {(((rating.twistiness + rating.surface_condition + rating.fun_factor + rating.scenery + rating.visibility) / 5) || 0).toFixed(1)}/5
                    </span>
                  </div>
                  {rating.comment && (
                    <p className="details-comment-body">{rating.comment}</p>
                  )}
                  {!rating.comment && (
                    <p className="details-comment-body no-comment">No comment provided</p>
                  )}
                </div>
              ))}
              {!commentsExpanded && hasMoreComments && (
                <button
                  type="button"
                  className="see-more-comments"
                  onClick={() => setCommentsExpanded(true)}
                >
                  +{hiddenCommentsCount} more comment{hiddenCommentsCount !== 1 ? 's' : ''}
                </button>
              )}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="modal-actions">
            <button type="button" onClick={onCancel} className="button-secondary">
              Close
            </button>
            <button
              type="button"
              onClick={() => setViewMode('rate')}
              className="button-primary"
            >
              Add a Rating
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Rating form view (existing behavior)
  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal-container" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{isNewRoad ? 'Save your road' : `Rate ${roadName || 'this road'}`}</h2>
          <p className="modal-subtitle">
            {isNewRoad ? 'Give it a name, rate your experience, and add your thoughts' : 'Share your experience with fellow riders'}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="modal-form">
          {isNewRoad && (
            <div className="name-field">
              <label htmlFor="road-name">Road Name</label>
              <input
                type="text"
                id="road-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., Snake Pass, Cat and Fiddle..."
                className="name-input"
                autoFocus
              />
            </div>
          )}

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
            {!isNewRoad && (
              <button type="button" onClick={() => setViewMode('details')} className="button-secondary">
                Back
              </button>
            )}
            {isNewRoad && (
              <button type="button" onClick={onCancel} className="button-secondary">
                Cancel
              </button>
            )}
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
