import ffi/sqlite
import gleam/otp/actor

pub type ExecutorMessage {
  ExecuteSource(run_id: Int)
  ExecuteTask(task_run_id: Int)
}

pub fn new(conn: sqlite.Connection) {
  actor.new(conn)
  |> actor.on_message(handle_message)
  |> actor.start()
}

fn handle_message(conn: sqlite.Connection, message: ExecutorMessage) {
  case message {
    ExecuteSource(id) -> {
      echo id
    }
    ExecuteTask(id) -> {
      echo id
    }
  }

  actor.continue(conn)
}
