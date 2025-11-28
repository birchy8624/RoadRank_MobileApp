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
    res.json(rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.post('/api/roads', async (req, res) => {
  try {
    const { path, twistiness, surface_condition, fun_factor, scenery, visibility } = req.body;
    const newRoad = await db.query(
      'INSERT INTO roads (path, twistiness, surface_condition, fun_factor, scenery, visibility) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [JSON.stringify(path), twistiness, surface_condition, fun_factor, scenery, visibility]
    );
    res.json(newRoad.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.listen(port, async () => {
  console.log(`Server is running on port: ${port}`);
  await initDb();
});
