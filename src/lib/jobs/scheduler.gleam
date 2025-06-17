import ffi/sqlite
import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import gleam/result
import lib/jobs/executor
import models/task

pub type SchedulerMessage {
  Schedule
}

type State {
  State(
    conn: sqlite.Connection,
    exec_sup: process.Subject(executor.ExecutorMessage),
  parent_sup: process.Subject()
  )
}

pub fn new(
  conn: sqlite.Connection,
  exec_sup: process.Subject(executor.ExecutorMessage),
) {
  actor.start(State(conn:, exec_sup:), handle_message)
}

pub fn schedule(sub: process.Subject(SchedulerMessage)) {
  actor.send(sub, Schedule)
}

fn handle_message(message: SchedulerMessage, state: State) {
  let _ = case message {
    Schedule -> {
      use tasks <- result.try(task.in_next_fifteen(state.conn))

      list.each(tasks, fn(task) {
        echo task

        process.send(state.exec_sup, executor.ExecuteSource(task.id))
      })

      Ok(Nil)
    }
  }

  // process.sleep(6000)

  // TODO: we need to recurse
  actor.continue(state)
}
