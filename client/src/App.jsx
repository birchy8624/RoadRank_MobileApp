import React from 'react';
import Map from './Map';
import './App.css';
import logo from './assets/roadrank-logo.svg';

function App() {
  return (
    <div className="App">
      <div className="app-gradient" />
      <header className="App-header">
        <div className="brand-block">
          <div className="logo-wrap">
            <img src={logo} alt="RoadRank" className="brand-logo" />
            <span className="logo-accent" />
          </div>
          <div className="headline">
            <p className="eyebrow">RoadRank</p>
            <h1>Ride-ready roads, ranked by riders.</h1>
            <p className="lede">
              Discover the most scenic and exhilarating routes, draw your own, and rate every twist
              with a modern, map-first experience.
            </p>
            <div className="chip-row">
              <span className="chip primary">Live community scores</span>
              <span className="chip muted">Draw &amp; save custom rides</span>
              <span className="chip outline">Glassmorphism UI kit</span>
            </div>
          </div>
        </div>

        <div className="header-grid">
          <div className="stat-card">
            <div className="stat-icon">🌄</div>
            <div>
              <p className="stat-label">Featured passes</p>
              <p className="stat-value">10 curated classics</p>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon">⚡</div>
            <div>
              <p className="stat-label">Instant ratings</p>
              <p className="stat-value">5-point smart sliders</p>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon">🧭</div>
            <div>
              <p className="stat-label">Navigate easily</p>
              <p className="stat-value">Search, draw, fly-to</p>
            </div>
          </div>
        </div>
      </header>

      <Map />

      <div className="legend">
        <div className="legend-header">
          <div>
            <p className="eyebrow">Heat legend</p>
            <h3>How routes are colored</h3>
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
