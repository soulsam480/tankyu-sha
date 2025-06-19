import ffi/sqlite
import gleam/erlang/process
import gleam/function
import gleam/list
import gleam/otp/actor
import gleam/result
import lib/jobs/executor
import lib/utils
import models/task
import models/task_run

pub type SchedulerMessage {
  Schedule
}

type State {
  State(
    conn: sqlite.Connection,
    exec_sup: process.Subject(executor.ExecutorMessage),
    self: process.Subject(SchedulerMessage),
  )
}

pub fn new(
  conn: sqlite.Connection,
  exec_sup: process.Subject(executor.ExecutorMessage),
) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let self = process.new_subject()

      process.send(self, Schedule)

      actor.Ready(
        State(conn:, exec_sup:, self:),
        process.new_selector()
          |> process.selecting(self, function.identity),
      )
    },
    init_timeout: 1000,
    loop: handle_message,
  ))
}

pub fn schedule(sub: process.Subject(SchedulerMessage)) {
  actor.send(sub, Schedule)
}

fn handle_message(message: SchedulerMessage, state: State) {
  let _ = case message {
    Schedule -> {
      use tasks <- result.try(task.in_next_5_hours(state.conn))

      list.each(tasks, fn(task) {
        use running_tasks <- result.try(task_run.of_task(task.id, state.conn))

        case utils.list_empty(running_tasks) {
          True -> {
            let assert Ok(new_task_run) =
              task_run.new()
              |> task_run.set_task_id(task.id)
              |> task_run.create(state.conn)

            process.send(
              state.exec_sup,
              executor.ExecuteSource(new_task_run.id),
            )
          }
          _ -> {
            Nil
          }
        }

        Ok(Nil)
      })

      Ok(Nil)
    }
  }

  process.sleep(6000)
  process.send(state.self, Schedule)

  actor.continue(state)
}
