import background_process/task_run_executor
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
import lifeguard
import models/task
import models/task_run

pub type SchedulerMessage {
  Schedule
}

pub opaque type State {
  State(
    conn: sqlite.Connection,
    task_run_exec_name: process.Name(
      lifeguard.PoolMsg(task_run_executor.ExecutorMessage),
    ),
    self: process.Name(SchedulerMessage),
  )
}

pub fn new_name() {
  process.new_name("Scheduler")
}

pub fn new(
  name: process.Name(SchedulerMessage),
  conn: sqlite.Connection,
  task_run_exec_name: process.Name(
    lifeguard.PoolMsg(task_run_executor.ExecutorMessage),
  ),
) {
  actor.new_with_initialiser(1000, fn(_) {
    let sub = process.named_subject(name)

    let selector = process.new_selector() |> process.select(sub)

    actor.initialised(State(conn:, task_run_exec_name:, self: name))
    |> actor.selecting(selector)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.named(name)
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

            let _ =
              lifeguard.send(
                process.named_subject(state.task_run_exec_name),
                task_run_executor.ExecuteTask(new_task_run.id),
                1000,
              )

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
  process.send_after(process.named_subject(state.self), 6000 * 5, Schedule)

  actor.continue(state)
}
