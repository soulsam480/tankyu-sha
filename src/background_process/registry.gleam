import background_process/scheduler
import gleam/erlang/process

pub type Registry {
  Registry(scheduler: process.Name(scheduler.SchedulerMessage))
}
