import ffi/sqlite
import gleam/otp/actor
import gleam/result
import lib/jobs/executor
import lib/jobs/scheduler

pub type SupMessage {
  Start
}

pub fn start() {
  use conn <- sqlite.with_connection(sqlite.db_path())

  actor.start(conn, handle_message)
}

fn handle_message(_m: SupMessage, conn: sqlite.Connection) {
  let _ = {
    use exec_sup <- result.try(executor.new(conn))

    use scheduler_sup <- result.try(scheduler.new(conn, exec_sup))

    scheduler.schedule(scheduler_sup)

    Ok(Nil)
  }

  actor.continue(conn)
}
