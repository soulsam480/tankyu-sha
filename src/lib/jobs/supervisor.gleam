import birl
import birl/duration
import ffi/sqlite
import gleam/erlang/process
import gleam/otp/supervisor
import lib/jobs/executor
import lib/jobs/scheduler
import models/task

pub type SupMessage {
  Start
}

pub fn start() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  // use exec_sup <- result.try(executor.new(conn))
  // use scheduler_sup <- result.try(scheduler.new(conn, exec_sup))

  let exec_worker =
    supervisor.worker(fn(_) { executor.new(conn) })
    |> supervisor.returning(fn(_, sub) { sub })

  let assert Ok(_sup) =
    supervisor.start(fn(children) {
      supervisor.add(children, exec_worker)
      |> supervisor.add(
        supervisor.worker(fn(exec_sup) { scheduler.new(conn, exec_sup) }),
      )
    })

  process.sleep_forever()
}

pub fn main() {
  // use conn <- sqlite.with_connection(sqlite.db_path())
  // let ts =
  //   task.new()
  //   |> task.set_delivery_at(
  //     birl.utc_now() |> birl.add(duration.hours(1)) |> birl.to_iso8601(),
  //   )
  //   |> task.create(conn)
  //
  // echo ts

  start()
}
