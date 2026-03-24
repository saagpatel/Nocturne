-- Nocturne: Supabase Schema Setup
-- Run this in the Supabase SQL Editor for your project.

-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Global measurements table
CREATE TABLE measurements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measured_at     TIMESTAMPTZ NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL,
    altitude_m      REAL NOT NULL,
    sky_brightness  REAL NOT NULL,             -- mag/arcsec²
    iphone_model    TEXT NOT NULL,
    calibration_ver TEXT NOT NULL,
    cloud_cover_pct INTEGER,
    is_cloudy       BOOLEAN NOT NULL DEFAULT FALSE,
    is_calibrated   BOOLEAN NOT NULL DEFAULT TRUE,
    bortle_class    INTEGER NOT NULL CHECK (bortle_class BETWEEN 1 AND 9)
);

-- Spatial index for heatmap queries
CREATE INDEX idx_measurements_location ON measurements USING GIST (location);
CREATE INDEX idx_measurements_measured_at ON measurements (measured_at DESC);
CREATE INDEX idx_measurements_bortle ON measurements (bortle_class);

-- Row-level security: public read, anon insert only (no update/delete)
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read" ON measurements FOR SELECT USING (true);
CREATE POLICY "Anon insert" ON measurements FOR INSERT WITH CHECK (true);

-- Heatmap tile function: returns aggregated grid cells for bounding box
CREATE OR REPLACE FUNCTION heatmap_tiles(
    min_lat FLOAT, max_lat FLOAT,
    min_lon FLOAT, max_lon FLOAT,
    grid_size_deg FLOAT DEFAULT 0.1
)
RETURNS TABLE (
    cell_lat FLOAT,
    cell_lon FLOAT,
    avg_brightness FLOAT,
    measurement_count INTEGER,
    avg_bortle INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND((ST_Y(m.location::geometry)::NUMERIC / grid_size_deg), 0)::FLOAT * grid_size_deg AS cell_lat,
        ROUND((ST_X(m.location::geometry)::NUMERIC / grid_size_deg), 0)::FLOAT * grid_size_deg AS cell_lon,
        AVG(m.sky_brightness)::FLOAT AS avg_brightness,
        COUNT(*)::INTEGER AS measurement_count,
        ROUND(AVG(m.bortle_class))::INTEGER AS avg_bortle
    FROM measurements m
    WHERE m.location && ST_MakeEnvelope(min_lon, min_lat, max_lon, max_lat, 4326)
      AND m.is_calibrated = TRUE
    GROUP BY cell_lat, cell_lon;
END;
$$ LANGUAGE plpgsql;
