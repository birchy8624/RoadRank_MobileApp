CREATE TABLE IF NOT EXISTS roads (
    id SERIAL PRIMARY KEY,
    path JSONB NOT NULL,
    twistiness INTEGER,
    surface_condition INTEGER,
    fun_factor INTEGER,
    scenery INTEGER,
    visibility INTEGER
);
