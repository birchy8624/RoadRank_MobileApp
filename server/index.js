const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const fs = require('fs');
const path = require('path');
const db = require('./db');

const parseNumeric = (value) => {
  const parsed = Number(value);
  if (Number.isNaN(parsed)) return null;
  return parsed;
};

const getRatingSummary = async (roadId) => {
  const { rows } = await db.query(
    `SELECT
        COUNT(*)::int AS rating_count,
        AVG(twistiness)::float AS avg_twistiness,
        AVG(surface_condition)::float AS avg_surface_condition,
        AVG(fun_factor)::float AS avg_fun_factor,
        AVG(scenery)::float AS avg_scenery,
        AVG(visibility)::float AS avg_visibility,
        AVG((twistiness + surface_condition + fun_factor + scenery + visibility)/5.0)::float AS avg_overall
      FROM road_ratings
      WHERE road_id = $1`,
    [roadId]
  );

  const summary = rows[0] || {};
  return {
    rating_count: summary.rating_count || 0,
    avg_twistiness: summary.avg_twistiness || null,
    avg_surface_condition: summary.avg_surface_condition || null,
    avg_fun_factor: summary.avg_fun_factor || null,
    avg_scenery: summary.avg_scenery || null,
    avg_visibility: summary.avg_visibility || null,
    avg_overall: summary.avg_overall || null,
  };
};

const initDb = async () => {
  try {
    const sql = fs.readFileSync(path.join(__dirname, 'db', 'init.sql')).toString();
    await db.query(sql);
    console.log('Database initialized successfully.');
  } catch (err) {
    console.error('Error initializing database:', err.message);
  }
};

app.get('/api/roads', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM roads');

    const roadsWithSummary = await Promise.all(
      rows.map(async (road) => {
        const summary = await getRatingSummary(String(road.id));
        return {
          ...road,
          rating_summary: summary,
        };
      })
    );

    res.json(roadsWithSummary);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.post('/api/roads', async (req, res) => {
  try {
    const { path, twistiness, surface_condition, fun_factor, scenery, visibility, name, comment } = req.body;
    const newRoad = await db.query(
      'INSERT INTO roads (path, twistiness, surface_condition, fun_factor, scenery, visibility, name) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [JSON.stringify(path), twistiness, surface_condition, fun_factor, scenery, visibility, name]
    );

    const roadId = String(newRoad.rows[0].id);
    await db.query(
      'INSERT INTO road_ratings (road_id, twistiness, surface_condition, fun_factor, scenery, visibility, comment) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [roadId, twistiness, surface_condition, fun_factor, scenery, visibility, comment || 'Original submission']
    );

    const summary = await getRatingSummary(roadId);

    res.json({
      ...newRoad.rows[0],
      rating_summary: summary,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.get('/api/roads/:id/ratings', async (req, res) => {
  try {
    const roadId = req.params.id;
    const ratingsResult = await db.query(
      'SELECT id, twistiness, surface_condition, fun_factor, scenery, visibility, comment, created_at FROM road_ratings WHERE road_id = $1 ORDER BY created_at DESC',
      [roadId]
    );

    const summary = await getRatingSummary(roadId);

    res.json({
      ratings: ratingsResult.rows,
      summary,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.post('/api/roads/:id/ratings', async (req, res) => {
  try {
    const roadId = req.params.id;
    const { twistiness, surface_condition, fun_factor, scenery, visibility, comment } = req.body;

    const validateScore = (score) => {
      const parsed = parseNumeric(score);
      return parsed >= 1 && parsed <= 5;
    };

    if (![twistiness, surface_condition, fun_factor, scenery, visibility].every(validateScore)) {
      return res.status(400).json({ message: 'All rating fields must be numbers between 1 and 5.' });
    }

    const inserted = await db.query(
      'INSERT INTO road_ratings (road_id, twistiness, surface_condition, fun_factor, scenery, visibility, comment) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [roadId, twistiness, surface_condition, fun_factor, scenery, visibility, comment]
    );

    const summary = await getRatingSummary(roadId);

    res.json({
      rating: inserted.rows[0],
      summary,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.listen(port, async () => {
  console.log(`Server is running on port: ${port}`);
  await initDb();
});
