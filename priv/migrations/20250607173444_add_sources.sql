-- migrate:up
CREATE TABLE sources (
    id INTEGER PRIMARY KEY,
    url TEXT NOT NULL,
    kind TEXT NOT NULL,
    meta TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX index_sources_on_kind ON sources (kind);

-- migrate:down
DROP TABLE sources;
