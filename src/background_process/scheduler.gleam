import background_process/task_run_executor
import clockwork
import clockwork/schedule
import ffi/sqlite
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/static_supervisor.{type Builder}
import lifeguard
import models/task
import models/task_run
import snag

pub fn schedule_tasks(
  builder: Builder,
  conn: sqlite.Connection,
  tasl_run_exec_name: process.Name(
    lifeguard.PoolMsg(task_run_executor.ExecutorMessage),
  ),
) -> Result(Builder, snag.Snag) {
  use tasks <- task.active_batch(conn)

  list.fold(tasks, builder, fn(acc, task) {
    let assert Ok(cron) = clockwork.from_string(task.schedule)

    let new_sub = process.new_subject()

    static_supervisor.add(
      acc,
      schedule.new("task_scheduler_" <> int.to_string(task.id), cron, fn() {
        let assert Ok(new_task_run) =
          task_run.new()
          |> task_run.set_task_id(task.id)
          |> task_run.create(conn)

        let _ =
          lifeguard.send(
            process.named_subject(tasl_run_exec_name),
            task_run_executor.ExecuteTask(new_task_run.id),
            1000,
          )

        Nil
      })
        |> schedule.with_logging()
        |> schedule.supervised(new_sub),
    )
  })
  |> Ok
}
