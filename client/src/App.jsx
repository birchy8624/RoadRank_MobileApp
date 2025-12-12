import React from 'react';
import Map from './Map';
import './App.css';
import logo from './assets/roadrank-logo.svg';

function App() {
  return (
    <div className="App">
      <div className="app-gradient" />

      <Map />

      <div className="legend">
        <div className="legend-header">
          <div className="legend-title">
            <img src={logo} alt="RoadRank" className="legend-logo" />
            <div>
              <p className="eyebrow">Heat legend</p>
              <h3>How routes are colored</h3>
            </div>
          </div>
          <span className="pill">Fun factor</span>
        </div>
        <div className="legend-item">
          <div className="legend-color" style={{ background: 'linear-gradient(90deg, #fca5a5, #ef4444)' }} />
          <div className="legend-text">
            <strong>1-2</strong> Challenging or low-rated surfaces
          </div>
        </div>
        <div className="legend-item">
          <div className="legend-color" style={{ background: 'linear-gradient(90deg, #fef08a, #f59e0b)' }} />
          <div className="legend-text">
            <strong>3-4</strong> Balanced blend of flow and comfort
          </div>
        </div>
        <div className="legend-item">
          <div className="legend-color" style={{ background: 'linear-gradient(90deg, #86efac, #10b981)' }} />
          <div className="legend-text">
            <strong>5</strong> Premium twisties with stellar views
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
