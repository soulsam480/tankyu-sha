-- migrate:up
CREATE TABLE task_runs (
    id INTEGER PRIMARY KEY,
    task_id INTEGER NOT NULL,
    digest_id INTEGER,
    status TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks (id),
    FOREIGN KEY (digest_id) REFERENCES digests (id)
);

CREATE INDEX index_task_runs_on_task_id ON task_runs (task_id);
CREATE INDEX index_task_runs_on_digest_id ON task_runs (digest_id);

-- migrate:down
DROP INDEX index_task_runs_on_task_id;
DROP INDEX index_task_runs_on_digest_id;
DROP TABLE task_runs;
