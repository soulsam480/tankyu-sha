-- migrate:up
CREATE TABLE sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    kind TEXT NOT NULL,
    meta TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    task_id INTEGER,
    FOREIGN KEY (task_id) REFERENCES tasks (id)
);

CREATE INDEX index_sources_on_kind ON sources (kind);

-- migrate:down
DROP TABLE sources;
