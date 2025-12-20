const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

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

  try {
    if (req.method === 'GET') {
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

      return res.status(200).json(roadsWithSummary);
    }

    if (req.method === 'POST') {
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

      return res.status(200).json({
        ...newRoad,
        rating_summary: summary,
      });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    console.error(err.message);
    return res.status(500).json({ error: 'Server error' });
  }
};
