-- migrate:up
CREATE TABLE digests (
    id INTEGER PRIMARY KEY,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- migrate:down
DROP TABLE digests;