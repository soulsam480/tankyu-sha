-- migrate:up
CREATE TABLE task_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
);

CREATE INDEX index_task_runs_on_task_id ON task_runs (task_id);

-- migrate:down
DROP INDEX index_task_runs_on_task_id;
DROP TABLE task_runs;
