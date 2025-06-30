-- migrate:up
ALTER TABLE tasks ADD COLUMN schedule TEXT;
ALTER TABLE tasks ADD COLUMN last_run_at TEXT;

-- migrate:down
ALTER TABLE tasks DROP COLUMN schedule;
ALTER TABLE tasks DROP COLUMN last_run_at;
