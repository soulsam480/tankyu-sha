import background_process/executor
import birl
import birl/duration
import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import lib/logger
import lib/utils
import models/task
import models/task_run

pub type SchedulerMessage {
  Schedule
}

pub opaque type State {
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
  actor.new_with_initialiser(1000, fn(self) {
    let selector = process.new_selector() |> process.select(self)

    actor.initialised(State(conn:, exec_sup:, self:))
    |> actor.selecting(selector)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

pub fn schedule(sub: process.Subject(SchedulerMessage)) {
  actor.send(sub, Schedule)
}

fn handle_message(state: State, message: SchedulerMessage) {
  let scheduler_logger = logger.new("Scheduler")

  let _ = case message {
    Schedule -> {
      logger.info(scheduler_logger, "Scheduling tasks")

      use tasks <- result.try(task.in_next_1_hour(state.conn))

      list.each(tasks, fn(task) {
        logger.info(
          scheduler_logger,
          "Processing task with id " <> int.to_string(task.id),
        )

        let assert Ok(running_tasks) = task_run.of_task(task.id, state.conn)

        case utils.list_is_empty(running_tasks) {
          True -> {
            let assert Ok(new_task_run) =
              task_run.new()
              |> task_run.set_task_id(task.id)
              |> task_run.create(state.conn)

            process.send(state.exec_sup, executor.ExecuteTask(new_task_run.id))

            logger.info(
              scheduler_logger,
              "Task scheduled with run id " <> int.to_string(new_task_run.id),
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

  logger.info(
    scheduler_logger,
    "Scheduled next run at "
      <> birl.utc_now() |> birl.add(duration.minutes(1)) |> birl.to_naive(),
  )

  // Schedule the next run in 5 minutes
  process.send_after(state.self, 6000 * 5, Schedule)

  actor.continue(state)
}
