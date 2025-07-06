import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/result
import lib/error

import gleam/option

pub opaque type Document {
  Document(
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

fn document_decoder() -> decode.Decoder(Document) {
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

  decode.success(Document(
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
  Document(
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

pub fn set_content(document: Document, content: String) {
  Document(..document, content:)
}

pub fn set_content_embedding(document: Document, content_embedding: List(Float)) {
  Document(..document, content_embedding:)
}

pub fn set_source_run_id(document: Document, source_run_id: Int) {
  Document(..document, source_run_id: option.Some(source_run_id))
}

pub fn set_task_run_id(document: Document, task_run_id: Int) {
  Document(..document, task_run_id: option.Some(task_run_id))
}

pub fn create(document: Document, connection: sqlite.Connection) {
  use res <- result.try(
    sqlite.exec(
      connection,
      "INSERT INTO documents (content, content_embedding, created_at, updated_at, meta, source_run_id, task_run_id) 
       VALUES (?, vec_f32(?), ?, ?, ?, ?, ?)
       RETURNING id;",
      [
        document.content |> sqlite.bind,
        document.content_embedding |> sqlite.vec,
        document.created_at |> sqlite.bind,
        document.updated_at |> sqlite.bind,
        document.meta |> sqlite.bind,
        document.source_run_id |> sqlite.option,
        document.task_run_id |> sqlite.option,
      ],
    ),
  )

  use id <- result.try(sqlite.get_inserted_id(res))

  Ok(Document(..document, id:))
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "select id, content, created_at, meta, task_run_id, source_run_id
from documents
where id = ?;",
    conn,
    [id |> sqlite.bind],
    document_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

pub fn update(document: Document, conn: sqlite.Connection) {
  let res =
    sqlite.exec(
      conn,
      "UPDATE documents 
       SET content = ?, 
           content_embedding = vec_f32(?), 
           updated_at = ?, 
           meta = ?, 
           source_run_id = ?, 
           task_run_id = ? 
       WHERE id = ?",
      [
        document.content |> sqlite.bind,
        document.content_embedding |> sqlite.vec,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        document.meta |> sqlite.bind,
        document.source_run_id |> sqlite.option,
        document.task_run_id |> sqlite.option,
        document.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_task_run(run_id: Int, vec: List(Float), conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "select id, content, created_at, meta, task_run_id
from documents
where task_run_id = ?
and content_embedding match vec_f32(?)
and k = 10
order by distance asc;",
    conn,
    [run_id |> sqlite.bind, vec |> sqlite.vec],
    document_decoder(),
  ))

  Ok(items)
}

pub fn delete_by_task_run_id(task_run_id: Int, conn: sqlite.Connection) {
  sqlite.exec(conn, "DELETE FROM documents WHERE task_run_id = ?", [
    task_run_id |> sqlite.bind,
  ])
}
