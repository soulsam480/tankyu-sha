import ffi/sqlite
import gleam/otp/actor

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
}

pub fn new(conn: sqlite.Connection) {
  actor.start(conn, handle_message)
}

fn handle_message(message: ExecutorMessage, conn: sqlite.Connection) {
  case message {
    ExecuteSource(id) -> {
      echo id
    }
  }

  actor.continue(conn)
}
