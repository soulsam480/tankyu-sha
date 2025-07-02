import background_process/cleaner
import background_process/registry
import background_process/scheduler
import background_process/source_run_executor
import background_process/source_run_ingestor
import background_process/task_run_executor
import background_process/task_run_ingestor
import ffi/sqlite
import gleam/erlang/process
import gleam/otp/static_supervisor
import gleam/otp/supervision
import lib/logger

/// main entry of all background processes
/// todo more comments
pub fn start(sub: process.Subject(registry.Registry)) {
  let sup_logger = logger.new("Supervisor")

  logger.info(sup_logger, "Starting supervisor")

  use conn <- sqlite.with_connection(sqlite.db_path())

  logger.info(sup_logger, "Connected to database")

  let task_run_ingestor_name = task_run_ingestor.new_name()
  let source_run_ingestor_name = source_run_ingestor.new_name()
  let source_run_executor_name = source_run_executor.new_name()
  let task_run_executor_name = task_run_executor.new_name()
  let cleaner_name = cleaner.new_name()
  let scheduler_name = scheduler.new_name()

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(task_run_ingestor.new(task_run_ingestor_name, conn))
    |> static_supervisor.add(source_run_ingestor.new(
      source_run_ingestor_name,
      conn,
      task_run_ingestor_name,
    ))
    |> static_supervisor.add(task_run_executor.new(
      task_run_executor_name,
      conn,
      source_run_executor_name,
    ))
    |> static_supervisor.add(source_run_executor.new(
      source_run_executor_name,
      conn,
      source_run_ingestor_name,
    ))
    |> static_supervisor.add(
      supervision.worker(fn() {
        scheduler.new(scheduler_name, conn, task_run_executor_name)
      }),
    )
    |> static_supervisor.add(
      supervision.worker(fn() { cleaner.new(cleaner_name, conn) }),
    )
    |> static_supervisor.start()

  logger.info(sup_logger, "Started supervisor")

  process.send(process.named_subject(cleaner_name), cleaner.CheckStaleRuns)
  process.send(process.named_subject(scheduler_name), scheduler.Schedule)

  process.send(sub, registry.Registry(scheduler: scheduler_name))

  process.sleep_forever()
}
