-- Migration: Add warnings column to road_ratings table
-- Run this on existing databases to add the warnings feature

-- Add warnings column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'road_ratings' AND column_name = 'warnings'
    ) THEN
        ALTER TABLE road_ratings ADD COLUMN warnings TEXT[];
    END IF;
END $$;
