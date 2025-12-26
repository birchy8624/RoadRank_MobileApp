const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

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

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { id: roadId } = req.query;

  try {
    if (req.method === 'GET') {
      const { data: ratings, error } = await supabase
        .from('road_ratings')
        .select('id, road_id, twistiness, surface_condition, fun_factor, scenery, visibility, comment, warnings, created_at')
        .eq('road_id', roadId)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching ratings:', error.message);
        return res.status(500).json({ error: 'Failed to fetch ratings' });
      }

      const summary = await getRatingSummary(roadId);

      return res.status(200).json({
        ratings: ratings || [],
        summary,
      });
    }

    if (req.method === 'POST') {
      const { twistiness, surface_condition, fun_factor, scenery, visibility, comment, warnings, device_id } = req.body;

      const validateScore = (score) => {
        const parsed = parseNumeric(score);
        return parsed >= 1 && parsed <= 5;
      };

      if (![twistiness, surface_condition, fun_factor, scenery, visibility].every(validateScore)) {
        return res.status(400).json({ message: 'All rating fields must be numbers between 1 and 5.' });
      }

      // Validate warnings if provided
      const validWarnings = ['speed_camera', 'potholes', 'traffic'];
      const sanitizedWarnings = Array.isArray(warnings)
        ? warnings.filter(w => validWarnings.includes(w))
        : null;

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
          warnings: sanitizedWarnings,
          device_id: device_id || null,
        }])
        .select()
        .single();

      if (error) {
        console.error('Error creating rating:', error.message);
        return res.status(500).json({ error: 'Failed to create rating' });
      }

      const summary = await getRatingSummary(roadId);

      return res.status(200).json({
        rating: inserted,
        summary,
      });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ error: 'Server error' });
  }
};
