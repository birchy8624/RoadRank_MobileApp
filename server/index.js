const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const { supabase } = require('./db');

const parseNumeric = (value) => {
  const parsed = Number(value);
  if (Number.isNaN(parsed)) return null;
  return parsed;
};

const getRatingSummary = async (roadId) => {
  const { data: ratings, error } = await supabase
    .from('road_ratings')
    .select('twistiness, surface_condition, fun_factor, scenery, visibility')
    .eq('road_id', roadId);

  if (error || !ratings || ratings.length === 0) {
    return {
      rating_count: 0,
      avg_twistiness: null,
      avg_surface_condition: null,
      avg_fun_factor: null,
      avg_scenery: null,
      avg_visibility: null,
      avg_overall: null,
    };
  }

  const count = ratings.length;
  const sum = (arr, key) => arr.reduce((acc, r) => acc + (r[key] || 0), 0);

  const avgTwistiness = sum(ratings, 'twistiness') / count;
  const avgSurfaceCondition = sum(ratings, 'surface_condition') / count;
  const avgFunFactor = sum(ratings, 'fun_factor') / count;
  const avgScenery = sum(ratings, 'scenery') / count;
  const avgVisibility = sum(ratings, 'visibility') / count;
  const avgOverall = (avgTwistiness + avgSurfaceCondition + avgFunFactor + avgScenery + avgVisibility) / 5;

  return {
    rating_count: count,
    avg_twistiness: avgTwistiness,
    avg_surface_condition: avgSurfaceCondition,
    avg_fun_factor: avgFunFactor,
    avg_scenery: avgScenery,
    avg_visibility: avgVisibility,
    avg_overall: avgOverall,
  };
};

app.get('/api/roads', async (req, res) => {
  try {
    const { data: roads, error } = await supabase
      .from('roads')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching roads:', error.message);
      return res.status(500).json({ error: 'Failed to fetch roads' });
    }

    const roadsWithSummary = await Promise.all(
      (roads || []).map(async (road) => {
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
    const { path, twistiness, surface_condition, fun_factor, scenery, visibility, name, comment, device_id } = req.body;

    const { data: newRoad, error: roadError } = await supabase
      .from('roads')
      .insert([{
        path: path,
        twistiness,
        surface_condition,
        fun_factor,
        scenery,
        visibility,
        name,
        device_id: device_id || null,
      }])
      .select()
      .single();

    if (roadError) {
      console.error('Error creating road:', roadError.message);
      return res.status(500).json({ error: 'Failed to create road' });
    }

    const roadId = String(newRoad.id);

    const { error: ratingError } = await supabase
      .from('road_ratings')
      .insert([{
        road_id: roadId,
        twistiness,
        surface_condition,
        fun_factor,
        scenery,
        visibility,
        comment: comment || 'Original submission',
      }]);

    if (ratingError) {
      console.error('Error creating initial rating:', ratingError.message);
    }

    const summary = await getRatingSummary(roadId);

    res.json({
      ...newRoad,
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

    const { data: ratings, error } = await supabase
      .from('road_ratings')
      .select('id, twistiness, surface_condition, fun_factor, scenery, visibility, comment, created_at')
      .eq('road_id', roadId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching ratings:', error.message);
      return res.status(500).json({ error: 'Failed to fetch ratings' });
    }

    const summary = await getRatingSummary(roadId);

    res.json({
      ratings: ratings || [],
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

    const { data: inserted, error } = await supabase
      .from('road_ratings')
      .insert([{
        road_id: roadId,
        twistiness,
        surface_condition,
        fun_factor,
        scenery,
        visibility,
        comment,
      }])
      .select()
      .single();

    if (error) {
      console.error('Error creating rating:', error.message);
      return res.status(500).json({ error: 'Failed to create rating' });
    }

    const summary = await getRatingSummary(roadId);

    res.json({
      rating: inserted,
      summary,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

app.listen(port, () => {
  console.log(`Server is running on port: ${port}`);
  console.log('Connected to Supabase');
});
