import background_process/cleaner
import background_process/executor
import background_process/ingestor
import background_process/scheduler
import ffi/sqlite
import gleam/erlang/process
import gleam/list
import gleam/otp/static_supervisor
import gleam/otp/supervision
import lib/logger
import models/task

/// main entry of all background processes
/// todo more comments
pub fn start() {
  let sup_logger = logger.new("Supervisor")

  logger.info(sup_logger, "Starting supervisor")

  use conn <- sqlite.with_connection(sqlite.db_path())

  // TODO: remove
  let assert Ok(all_tasks) = task.all(conn)

  list.each(all_tasks, task.destroy(_, conn))

  // TODO: remove above

  logger.info(sup_logger, "Connected to database")

  let assert Ok(ingest_actor) = ingestor.new(conn)

  logger.info(sup_logger, "Created ingestor actor")

  let assert Ok(exec_actor) = executor.new(conn, ingest_actor.data)

  logger.info(sup_logger, "Created executor actor")

  let assert Ok(scheduler_actor) = scheduler.new(conn, exec_actor.data)

  logger.info(sup_logger, "Created scheduler actor")

  let assert Ok(cleaner_actor) = cleaner.new(conn)
  logger.info(sup_logger, "Created cleaner actor")

  let assert Ok(_) =
    // TODO: 1. flatten all actor messages to separate actors
    // 2. pool for actors
    // 3. keep playwright instance alive in background
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(supervision.worker(fn() { Ok(ingest_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(exec_actor) }))
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
