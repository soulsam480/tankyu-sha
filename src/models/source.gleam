import gleam/option.{type Option}

pub type Source {
  Source(
    id: Int,
    url: String,
    kind: String,
    meta: Option(String),
    created_at: String,
    updated_at: String,
  )
}
