-- migrate:up
CREATE TABLE source_runs (
    id INTEGER PRIMARY KEY,
    temp_source TEXT,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    source_id INTEGER NOT NULL,
    digest_id INTEGER,
    task_run_id INTEGER,
    FOREIGN KEY (source_id) REFERENCES sources (id),
    FOREIGN KEY (digest_id) REFERENCES digests (id),
    FOREIGN KEY (task_run_id) REFERENCES task_runs (id)
);

CREATE INDEX index_source_runs_on_source_id ON source_runs (source_id);
CREATE INDEX index_source_runs_on_digest_id ON source_runs (digest_id);
CREATE INDEX index_source_runs_on_task_run_id ON source_runs (task_run_id);

-- migrate:down
DROP INDEX index_source_runs_on_source_id;
DROP INDEX index_source_runs_on_digest_id;
DROP INDEX index_source_runs_on_task_run_id;

DROP TABLE source_runs;
