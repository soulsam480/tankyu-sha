import background_process/executor
import background_process/ingestor
import background_process/scheduler
import birl
import birl/duration
import ffi/sqlite
import gleam/erlang/process
import gleam/list
import gleam/otp/static_supervisor
import gleam/otp/supervision
import lib/logger
import models/source
import models/task

/// main entry of all background processes
/// todo more comments
pub fn start() {
  let sup_logger = logger.new("Supervisor")

  logger.info(sup_logger, "Starting supervisor")

  use conn <- sqlite.with_connection(sqlite.db_path())

  logger.info(sup_logger, "Connected to database")

  let assert Ok(ingest_actor) = ingestor.new(conn)

  logger.info(sup_logger, "Created ingestor actor")

  let assert Ok(exec_actor) = executor.new(conn, ingest_actor.data)

  logger.info(sup_logger, "Created executor actor")

  let assert Ok(scheduler_actor) = scheduler.new(conn, exec_actor.data)

  logger.info(sup_logger, "Created scheduler actor")

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(supervision.worker(fn() { Ok(ingest_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(exec_actor) }))
    |> static_supervisor.add(supervision.worker(fn() { Ok(scheduler_actor) }))
    |> static_supervisor.start()

  logger.info(sup_logger, "Started supervisor")

  process.send(scheduler_actor.data, scheduler.Schedule)
  logger.info(sup_logger, "Started scheduler")

  process.sleep_forever()
}

pub fn main() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  let assert Ok(all_tasks) = task.all(conn)

  list.each(all_tasks, task.destroy(_, conn))

  let delivery_times = [
    birl.utc_now() |> birl.add(duration.hours(1)) |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.hours(2)) |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.hours(5)) |> birl.to_iso8601(),
    birl.utc_now()
      |> birl.add(duration.hours(5))
      |> birl.add(duration.minutes(10))
      |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.hours(8)) |> birl.to_iso8601(),
    birl.utc_now() |> birl.add(duration.hours(10)) |> birl.to_iso8601(),
  ]

  let articles = [
    "https://lite.cnn.com/2025/06/21/weather/heat-dome-climate",
    "https://lite.cnn.com/2025/06/21/politics/iran-b-2-bombers-trump",
    "https://lite.cnn.com/2025/06/20/us/mahmoud-khalil-ordered-released-by-judge",
    "https://lite.cnn.com/us/ice-immigration-officers-face-masks",
    "https://lite.cnn.com/2025/06/21/middleeast/americans-israel-desperate-get-out-intl-latam",
    "https://lite.cnn.com/2025/06/21/sport/jacob-misiorowski-125-year-old-record-spt",
  ]

  list.zip(list.shuffle(delivery_times), list.shuffle(articles))
  |> list.each(fn(it) {
    let #(delivery_time, article) = it

    let assert Ok(ts) =
      task.new()
      |> task.set_delivery_at(delivery_time)
      |> task.create(conn)

    source.new()
    |> source.set_task_id(ts.id)
    |> source.set_kind(source.News)
    |> source.set_url(article)
    |> source.create(conn)
  })

  start()

  Ok(Nil)
}
