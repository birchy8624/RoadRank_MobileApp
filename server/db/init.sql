CREATE TABLE IF NOT EXISTS roads (
    id SERIAL PRIMARY KEY,
    path JSONB NOT NULL,
    twistiness INTEGER,
    surface_condition INTEGER,
    fun_factor INTEGER,
    scenery INTEGER,
    visibility INTEGER,
    name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS road_ratings (
    id SERIAL PRIMARY KEY,
    road_id TEXT NOT NULL,
    twistiness INTEGER CHECK (twistiness BETWEEN 1 AND 5),
    surface_condition INTEGER CHECK (surface_condition BETWEEN 1 AND 5),
    fun_factor INTEGER CHECK (fun_factor BETWEEN 1 AND 5),
    scenery INTEGER CHECK (scenery BETWEEN 1 AND 5),
    visibility INTEGER CHECK (visibility BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
