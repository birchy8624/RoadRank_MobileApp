-- RoadRank Seed Data
-- Run this after init.sql to add some classic UK driving roads

-- Insert classic UK roads
INSERT INTO roads (path, twistiness, surface_condition, fun_factor, scenery, visibility, name) VALUES
(
  '[{"lat": 53.4040, "lng": -1.8186}, {"lat": 53.4050, "lng": -1.8300}, {"lat": 53.4070, "lng": -1.8450}, {"lat": 53.4100, "lng": -1.8600}, {"lat": 53.4120, "lng": -1.8750}]',
  5, 3, 5, 5, 4, 'Snake Pass (A57)'
),
(
  '[{"lat": 53.2650, "lng": -2.0200}, {"lat": 53.2700, "lng": -2.0100}, {"lat": 53.2750, "lng": -2.0000}, {"lat": 53.2800, "lng": -1.9900}]',
  4, 4, 5, 5, 3, 'Cat and Fiddle (A537)'
),
(
  '[{"lat": 54.4010, "lng": -3.2100}, {"lat": 54.4050, "lng": -3.2000}, {"lat": 54.4090, "lng": -3.1900}, {"lat": 54.4120, "lng": -3.1800}]',
  5, 2, 4, 5, 4, 'Hardknott Pass'
),
(
  '[{"lat": 57.3800, "lng": -5.7500}, {"lat": 57.3850, "lng": -5.7400}, {"lat": 57.3900, "lng": -5.7300}, {"lat": 57.3950, "lng": -5.7200}, {"lat": 57.4000, "lng": -5.7100}]',
  5, 3, 5, 5, 3, 'Bealach na Ba'
),
(
  '[{"lat": 54.3600, "lng": -2.1800}, {"lat": 54.3650, "lng": -2.1700}, {"lat": 54.3700, "lng": -2.1600}, {"lat": 54.3750, "lng": -2.1500}]',
  4, 4, 4, 5, 4, 'Buttertubs Pass (B6270)'
),
(
  '[{"lat": 57.3200, "lng": -4.4200}, {"lat": 57.3100, "lng": -4.4100}, {"lat": 57.3000, "lng": -4.4000}, {"lat": 57.2900, "lng": -4.3900}]',
  3, 5, 4, 5, 5, 'Loch Ness Scenic Route'
),
(
  '[{"lat": 54.4300, "lng": -3.1100}, {"lat": 54.4350, "lng": -3.1000}, {"lat": 54.4400, "lng": -3.0900}, {"lat": 54.4450, "lng": -3.0800}]',
  5, 3, 4, 4, 3, 'Wrynose Pass'
),
(
  '[{"lat": 57.2200, "lng": -3.3200}, {"lat": 57.2250, "lng": -3.3100}, {"lat": 57.2300, "lng": -3.3000}, {"lat": 57.2350, "lng": -3.2900}, {"lat": 57.2400, "lng": -3.2800}]',
  3, 4, 3, 5, 4, 'Cairngorms Pass (A939)'
),
(
  '[{"lat": 56.2300, "lng": -4.7500}, {"lat": 56.2350, "lng": -4.7400}, {"lat": 56.2400, "lng": -4.7300}, {"lat": 56.2450, "lng": -4.7200}]',
  4, 4, 4, 5, 4, 'Rest and Be Thankful (A83)'
),
(
  '[{"lat": 53.0900, "lng": -3.5200}, {"lat": 53.0950, "lng": -3.5100}, {"lat": 53.1000, "lng": -3.5000}, {"lat": 53.1050, "lng": -3.4900}, {"lat": 53.1100, "lng": -3.4800}]',
  5, 4, 5, 4, 4, 'Evo Triangle (B4391/B5105/A543)'
);

-- Insert initial ratings for each road (Original submissions)
INSERT INTO road_ratings (road_id, twistiness, surface_condition, fun_factor, scenery, visibility, comment)
SELECT
  id::text,
  twistiness,
  surface_condition,
  fun_factor,
  scenery,
  visibility,
  'Original submission'
FROM roads;
