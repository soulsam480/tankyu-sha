import birl
import ffi/sqlite
import gleam/option
import gleam/result

pub opaque type Digest {
  Digest(
    digest_id: Int,
    task_run_id: option.Option(Int),
    source_run_id: option.Option(Int),
    content_embedding: List(Float),
    content: String,
    created_at: String,
    updated_at: String,
    meta: String,
  )
}

pub fn new() {
  Digest(
    digest_id: 0,
    content: "",
    content_embedding: [],
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
    meta: "{}",
    source_run_id: option.None,
    task_run_id: option.None,
  )
}

pub fn content(digest: Digest, content: String) {
  Digest(..digest, content:)
}

pub fn content_embedding(digest: Digest, content_embedding: List(Float)) {
  Digest(..digest, content_embedding:)
}
// pub fn save(digest: Digest, connection: sqlite.Connection) {
//   use _ <- result.try(
//     sqlite.exec(
//       connection,
//       "INSERT INTO digests (content, content_embedding, created_at, updated_at, meta, source_run_id, task_run_id) VALUES (?, vec_f32(?), ?, ?, ?, ?, ?)",
//       [
//         digest.content |> sqlite.string,
//         digest.content_embedding,
//         digest.created_at |> sqlite.string,
//         digest.updated_at |> sqlite.string,
//         digest.meta |> sqlite.string,
//         digest.source_run_id |> sqlite.int,
//         digest.task_run_id |> sqlite.int,
//       ],
//     ),
//   )
//   todo
// }
