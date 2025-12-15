import React, { useEffect } from 'react';
import './Snackbar.css';

/**
 * Snackbar notification component
 * @param {Object} props
 * @param {string} props.message - The message to display
 * @param {string} props.type - Type of snackbar: 'error', 'warning', 'success', 'info'
 * @param {boolean} props.open - Whether the snackbar is visible
 * @param {function} props.onClose - Callback when snackbar should close
 * @param {number} props.duration - Auto-hide duration in ms (default: 5000, 0 for no auto-hide)
 */
function Snackbar({ message, type = 'info', open, onClose, duration = 5000 }) {
  useEffect(() => {
    if (open && duration > 0) {
      const timer = setTimeout(() => {
        onClose();
      }, duration);
      return () => clearTimeout(timer);
    }
  }, [open, duration, onClose]);

  if (!open) return null;

  const icons = {
    error: '!',
    warning: '!',
    success: '✓',
    info: 'i'
  };

  return (
    <div className={`snackbar snackbar-${type}`} role="alert">
      <div className="snackbar-icon">{icons[type]}</div>
      <span className="snackbar-message">{message}</span>
      <button
        className="snackbar-close"
        onClick={onClose}
        aria-label="Close notification"
      >
        ✕
      </button>
    </div>
  );
}

export default Snackbar;
