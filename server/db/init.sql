-- RoadRank Supabase Schema
-- Run this in the Supabase SQL Editor to set up your database

-- Create roads table
CREATE TABLE IF NOT EXISTS roads (
    id SERIAL PRIMARY KEY,
    path JSONB NOT NULL,
    twistiness INTEGER,
    surface_condition INTEGER,
    fun_factor INTEGER,
    scenery INTEGER,
    visibility INTEGER,
    name TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on device_id for efficient "My Roads" queries
CREATE INDEX IF NOT EXISTS idx_roads_device_id ON roads(device_id);

-- Create road_ratings table
CREATE TABLE IF NOT EXISTS road_ratings (
    id SERIAL PRIMARY KEY,
    road_id TEXT NOT NULL,
    twistiness INTEGER CHECK (twistiness BETWEEN 1 AND 5),
    surface_condition INTEGER CHECK (surface_condition BETWEEN 1 AND 5),
    fun_factor INTEGER CHECK (fun_factor BETWEEN 1 AND 5),
    scenery INTEGER CHECK (scenery BETWEEN 1 AND 5),
    visibility INTEGER CHECK (visibility BETWEEN 1 AND 5),
    comment TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on device_id for efficient "My Ratings" queries
CREATE INDEX IF NOT EXISTS idx_road_ratings_device_id ON road_ratings(device_id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_road_ratings_road_id ON road_ratings(road_id);
CREATE INDEX IF NOT EXISTS idx_roads_created_at ON roads(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE roads ENABLE ROW LEVEL SECURITY;
ALTER TABLE road_ratings ENABLE ROW LEVEL SECURITY;

-- Create policies to allow public read/write access
-- (For a production app, you'd want to restrict write access to authenticated users)
CREATE POLICY "Allow public read access on roads" ON roads
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert access on roads" ON roads
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read access on road_ratings" ON road_ratings
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert access on road_ratings" ON road_ratings
    FOR INSERT WITH CHECK (true);
