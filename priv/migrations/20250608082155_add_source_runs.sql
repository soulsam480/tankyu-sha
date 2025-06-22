-- migrate:up
CREATE TABLE source_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    status TEXT NOT NULL,
    content TEXT,
    summary TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    source_id INTEGER NOT NULL,
    task_run_id INTEGER,
    FOREIGN KEY (source_id) REFERENCES sources (id) ON DELETE CASCADE,
    FOREIGN KEY (task_run_id) REFERENCES task_runs (id) ON DELETE CASCADE
);

CREATE INDEX index_source_runs_on_source_id ON source_runs (source_id);
CREATE INDEX index_source_runs_on_task_run_id ON source_runs (task_run_id);

-- migrate:down
DROP INDEX index_source_runs_on_source_id;
DROP INDEX index_source_runs_on_task_run_id;

DROP TABLE source_runs;
