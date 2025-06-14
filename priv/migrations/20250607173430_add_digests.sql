-- migrate:up
CREATE VIRTUAL TABLE digests using vec0(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_run_id INTEGER PARTITION KEY,
    source_run_id INTEGER PARTITION KEY,
    content_embedding FLOAT[768],
    content TEXT,
    created_at TEXT,
    updated_at TEXT,
    meta TEXT
);

-- migrate:down
DROP TABLE digests;
