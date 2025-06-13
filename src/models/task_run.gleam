import gleam/option.{type Option}

pub type TaskRun {
  TaskRun(
    id: Int,
    task_id: Int,
    digest_id: Option(Int),
    status: String,
    content: String,
    created_at: String,
    updated_at: String,
  )
}
