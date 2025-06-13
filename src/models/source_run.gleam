import gleam/option.{type Option}

pub type SourceRun {
  SourceRun(
    id: Int,
    status: String,
    created_at: String,
    updated_at: String,
    source_id: Int,
    digest_id: Option(Int),
    task_run_id: Option(Int),
  )
}
