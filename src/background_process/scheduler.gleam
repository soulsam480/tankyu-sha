import background_process/task_run_executor
import clockwork
import ffi/sqlite
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/time/calendar
import gleam/time/timestamp
import lib/logger
import lifeguard
import models/task
import models/task_run

pub type SchedulerMessage {
  Schedule
  ScheduleExec(task_id: Int)
}

type State {
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

fn handle_message(state: State, message: SchedulerMessage) {
  let scheduler_logger = logger.new("Scheduler")

  let _ = case message {
    Schedule -> {
      logger.info(scheduler_logger, "Scheduling tasks")

      use tasks <- task.active_batch(state.conn)

      // NOTE: here we only look at tasks whose next occurance is not read already
      list.each(tasks, fn(task) {
        case result.is_ok(schedule_task(task, state.conn, state.self)) {
          True -> {
            logger.info(
              scheduler_logger,
              "Scheduled task with id " <> int.to_string(task.id),
            )
          }
          _ -> {
            Nil
          }
        }
      })

      Ok(Nil)
    }

    ScheduleExec(task_id) -> {
      use task <- result.try(task.find(task_id, state.conn))

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
        "Scheduled run for task " <> int.to_string(task.id),
      )

      Ok(Nil)
    }
  }

  // Schedule the next run in 5 minutesAdd commentMore actions
  process.send_after(process.named_subject(state.self), 6000 * 5, Schedule)

  actor.continue(state)
}

pub fn schedule_task(
  task: task.Task,
  conn: sqlite.Connection,
  scheduler_name: process.Name(SchedulerMessage),
) {
  let assert Ok(cron) = clockwork.from_string(task.schedule)

  let next =
    clockwork.next_occurrence(
      given: cron,
      from: timestamp.system_time(),
      with_offset: calendar.local_offset(),
    )
    |> timestamp.to_unix_seconds
    |> float.round

  // 1. to schedule
  let after_ms =
    int.subtract(
      next
        |> int.multiply(1000),
      timestamp.system_time()
        |> timestamp.to_unix_seconds
        |> float.round
        |> int.multiply(1000),
    )

  // 2. to store
  let next_str = next |> int.to_string

  case option.unwrap(task.last_run_at, "") == next_str {
    True -> {
      Ok(Nil)
    }

    False -> {
      process.send_after(
        process.named_subject(scheduler_name),
        after_ms,
        ScheduleExec(task.id),
      )

      use _ <- result.try(
        task.set_last_run_at(task, next |> int.to_string)
        |> task.update(conn),
      )

      Ok(Nil)
    }
  }
}
