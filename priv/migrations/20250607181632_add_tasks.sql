-- migrate:up
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    topic TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    delivery_at TEXT NOT NULL,
    delivery_route TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- migrate:down
DROP TABLE tasks;