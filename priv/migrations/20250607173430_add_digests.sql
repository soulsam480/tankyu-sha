-- migrate:up
CREATE VIRTUAL TABLE digests using vec0(
    digest_id INTEGER PRIMARY KEY,
    task_run_id INTEGER PARTITION KEY,
    source_run_id INTEGER PARTITION KEY,
    content_embedding FLOAT[768],
    -- NOTE: this is the summary and not the raw text
    content TEXT,
    created_at TEXT,
    updated_at TEXT,
    meta TEXT
);

-- migrate:down
DROP TABLE digests;
