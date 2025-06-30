**Project Goal:** We are enhancing the task scheduling functionality in the `tankyu-sha` application. The goal is to move from a simple, one-time `delivery_at` timestamp to a flexible, recurring scheduling system using cron expressions. This will allow tasks to be scheduled multiple times or at complex intervals (e.g., "every Monday at 1 AM").

**Key Decisions & Plan:**

1.  **Database Schema Change:** We decided to modify the `tasks` table in the SQLite database.
    *   We created and executed a migration to replace the `delivery_at` column with two new columns:
        *   `schedule` (TEXT): To store the cron expression for the task.
        *   `last_run_at` (TEXT): A timestamp to track the last execution time, which is crucial for preventing duplicate runs of the same task.

2.  **External Dependency:** We added the `clockwork` Gleam library to the project to handle parsing and evaluation of cron expressions.

3.  **Code Implementation Plan:**
    *   **Model (`src/models/task.gleam`):** Update the `Task` type and its related functions (`task_decoder`, `create`, `update`) to reflect the new database schema. The main goal is to create a new function, `due_tasks`, which will fetch all active tasks and use the `clockwork` library to determine which ones are due to run based on their `schedule` and `last_run_at` time.
    *   **Scheduler (`src/background_process/scheduler.gleam`):** Update the scheduler's logic to use the new `due_tasks` function. For each due task, it will create a `task_run` and then update the task's `last_run_at` field in the database.

**Current Status & Roadblock:**

We are currently in the middle of implementing the changes to `src/models/task.gleam`. The process has involved several cycles of writing code and then running `gleam check` to identify compilation errors.

The primary roadblock is a series of compilation errors related to:
*   **Incorrect API Usage:** We are struggling with the correct function names and usage patterns for the `clockwork` and `birl` libraries.
*   **Gleam Type System:** There have been mismatches and incorrect handling of `Result`, `Option`, and list transformation functions (`list.filter_map` vs. `list.try_map`).
*   **Error Handling:** Incorrectly trying to create errors with `error.new` instead of the project's `snag.new` convention.

Just before you requested this summary, I had identified that my repeated errors were due to not knowing the correct library APIs. I had just read `lib/error.gleam` to understand error creation and was about to read the `clockwork` library's documentation to resolve the API usage errors.