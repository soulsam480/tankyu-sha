import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/result
import lib/error

import gleam/option

pub opaque type Digest {
  Digest(
    id: Int,
    task_run_id: option.Option(Int),
    source_run_id: option.Option(Int),
    content_embedding: List(Float),
    content: String,
    created_at: String,
    updated_at: String,
    meta: String,
  )
}

fn digest_decoder() -> decode.Decoder(Digest) {
  use id <- decode.field("id", decode.int)

  use task_run_id <- decode.optional_field(
    "task_run_id",
    option.None,
    decode.optional(decode.int),
  )

  use source_run_id <- decode.optional_field(
    "source_run_id",
    option.None,
    decode.optional(decode.int),
  )

  use content_embedding <- decode.optional_field(
    "content_embedding",
    [],
    decode.list(decode.float),
  )

  use content <- decode.optional_field("content", "", decode.string)
  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)
  use meta <- decode.optional_field("meta", "{}", decode.string)

  decode.success(Digest(
    id:,
    task_run_id:,
    source_run_id:,
    content_embedding:,
    content:,
    created_at:,
    updated_at:,
    meta:,
  ))
}

pub fn new() {
  Digest(
    id: 0,
    content: "",
    content_embedding: [],
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
    meta: "{}",
    source_run_id: option.None,
    task_run_id: option.None,
  )
}

pub fn set_content(digest: Digest, content: String) {
  Digest(..digest, content:)
}

pub fn set_content_embedding(digest: Digest, content_embedding: List(Float)) {
  Digest(..digest, content_embedding:)
}

pub fn set_source_run_id(digest: Digest, source_run_id: Int) {
  Digest(..digest, source_run_id: option.Some(source_run_id))
}

pub fn set_task_run_id(digest: Digest, task_run_id: Int) {
  Digest(..digest, task_run_id: option.Some(task_run_id))
}

pub fn create(digest: Digest, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO digests (content, content_embedding, created_at, updated_at, meta, source_run_id, task_run_id) 
       VALUES (?, vec_f32(?), ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        digest.content |> sqlite.bind,
        digest.content_embedding |> sqlite.vec,
        digest.created_at |> sqlite.bind,
        digest.updated_at |> sqlite.bind,
        digest.meta |> sqlite.bind,
        digest.source_run_id |> sqlite.option,
        digest.task_run_id |> sqlite.option,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(Digest(..digest, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "select id, content, created_at, meta, task_run_id, source_run_id
from digests
where id = ?;",
    conn,
    [id |> sqlite.bind],
    digest_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

pub fn update(digest: Digest, conn: sqlite.Connection) {
  let res =
    sqlite.exec(
      conn,
      "UPDATE digests 
       SET content = ?, 
           content_embedding = vec_f32(?), 
           updated_at = ?, 
           meta = ?, 
           source_run_id = ?, 
           task_run_id = ? 
       WHERE id = ?",
      [
        digest.content |> sqlite.bind,
        digest.content_embedding |> sqlite.vec,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        digest.meta |> sqlite.bind,
        digest.source_run_id |> sqlite.option,
        digest.task_run_id |> sqlite.option,
        digest.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_task_run(run_id: Int, vec: List(Float), conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "select id, content, created_at, meta, task_run_id
from digests
where task_run_id = ?
and content_embedding match vec_f32(?)
and k = 10
order by distance asc;",
    conn,
    [run_id |> sqlite.bind, vec |> sqlite.vec],
    digest_decoder(),
  ))

  Ok(items)
}

pub fn of_source_run(run_id: Int, vec: List(Float), conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "select id, content, created_at, meta, source_run_id
from digests
where source_run_id = ?
and content_embedding match vec_f32(?)
and k = 10
order by distance asc;",
    conn,
    [run_id |> sqlite.bind, vec |> sqlite.vec],
    digest_decoder(),
  ))

  Ok(items)
}
