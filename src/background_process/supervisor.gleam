import background_process/cleaner
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
pub fn start() {
  let sup_logger = logger.new("Supervisor")

  logger.info(sup_logger, "Starting supervisor")

  use conn <- sqlite.with_connection(sqlite.db_path())

  // // TODO: remove
  // let assert Ok(all_tasks) = task.all(conn)
  //
  // list.each(all_tasks, task.destroy(_, conn))
  //
  // // TODO: remove above

  logger.info(sup_logger, "Connected to database")

  let assert Ok(task_ingest_actor) = task_run_ingestor.new(conn)

  logger.info(sup_logger, "Created task ingestor actor")

  let assert Ok(source_ingest_actor) =
    source_run_ingestor.new(conn, task_ingest_actor.data)

  logger.info(sup_logger, "Created source ingestor actor")

  let assert Ok(source_exec_actor) =
    source_run_executor.new(conn, source_ingest_actor.data)

  logger.info(sup_logger, "Created source executor actor")

  let assert Ok(task_exec_actor) =
    task_run_executor.new(
      conn,
      source_ingest_actor.data,
      source_exec_actor.data,
    )

  logger.info(sup_logger, "Created task executor actor")

  let assert Ok(scheduler_actor) = scheduler.new(conn, task_exec_actor.data)

  logger.info(sup_logger, "Created scheduler actor")

  let assert Ok(cleaner_actor) = cleaner.new(conn)
  logger.info(sup_logger, "Created cleaner actor")

  let assert Ok(_) =
    // TODO: 1. flatten all actor messages to separate actors
    // 2. pool for actors
    // 3. keep playwright instance alive in background
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(supervision.worker(fn() { Ok(task_ingest_actor) }))
    |> static_supervisor.add(
      supervision.worker(fn() { Ok(source_ingest_actor) }),
    )
    |> static_supervisor.add(supervision.worker(fn() { Ok(task_exec_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(source_exec_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(scheduler_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(cleaner_actor) }))
    |> static_supervisor.start()

  logger.info(sup_logger, "Started supervisor")

  process.send(scheduler_actor.data, scheduler.Schedule)
  logger.info(sup_logger, "Started scheduler")

  process.send(cleaner_actor.data, cleaner.CheckStaleRuns)
  logger.info(sup_logger, "Started cleaner")

  process.sleep_forever()
}
