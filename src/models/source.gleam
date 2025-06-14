import birl
import ffi/sqlite
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error

pub type SourceKind {
  Search
  Feed
  News
}

pub type Source {
  Source(
    id: Int,
    url: String,
    kind: SourceKind,
    meta: dict.Dict(String, String),
    task_id: Option(Int),
    created_at: String,
    updated_at: String,
  )
}

fn source_decoder() -> decode.Decoder(Source) {
  use id <- decode.field("id", decode.int)
  use url <- decode.optional_field("url", "", decode.string)
  use kind <- decode.optional_field("kind", "", decode.string)

  use task_id <- decode.optional_field(
    "task_id",
    option.None,
    decode.optional(decode.int),
  )

  use meta <- decode.optional_field("meta", dict.new(), decode_meta())

  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)

  let assert Ok(parsed_kind) = decode_kind(kind)

  decode.success(Source(
    id:,
    url:,
    kind: parsed_kind,
    meta:,
    created_at:,
    task_id:,
    updated_at:,
  ))
}

fn decode_kind(kind: String) {
  case kind {
    "Search" -> Ok(Search)
    "Feed" -> Ok(Feed)
    "News" -> Ok(News)
    _ -> Error(Nil)
  }
}

fn encode_kind(kind: SourceKind) {
  case kind {
    Search -> "Search"
    Feed -> "Feed"
    News -> "News"
  }
}

fn decode_meta() {
  decode.string
  |> decode.map(fn(val) {
    json.parse(val, decode.dict(decode.string, decode.string))
    |> result.unwrap(dict.new())
  })
}

fn encode_meta(meta: dict.Dict(String, String)) {
  json.dict(meta, fn(it) { it }, json.string) |> json.to_string
}

pub fn new() {
  Source(
    id: -1,
    url: "",
    kind: Search,
    meta: dict.new(),
    task_id: option.None,
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
  )
}

pub fn set_url(source: Source, url: String) {
  Source(..source, url:)
}

pub fn set_kind(source: Source, kind: SourceKind) {
  Source(..source, kind:)
}

/// this overrides an existing meta key inside source
pub fn set_meta(source: Source, meta: dict.Dict(String, String)) {
  Source(..source, meta: dict.combine(source.meta, meta, fn(_, b) { b }))
}

pub fn set_task_id(source: Source, task_id: Int) {
  Source(..source, task_id: option.Some(task_id))
}

pub fn create(source: Source, connection: sqlite.Connection) {
  let res =
    sqlite.exec(
      connection,
      "INSERT INTO sources (url, kind, meta, task_id, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, ?)",
      [
        source.url |> sqlite.bind,
        encode_kind(source.kind) |> sqlite.bind,
        source.meta |> encode_meta |> sqlite.bind,
        source.task_id |> sqlite.option,
        source.created_at |> sqlite.bind,
        source.updated_at |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, url, kind, meta, task_id, created_at, updated_at 
     FROM sources 
     WHERE id = ?;",
    conn,
    [id |> sqlite.bind],
    source_decoder(),
  ))

  use first <- result.try(
    list.first(items) |> error.map_to_snag("Invalid result"),
  )

  Ok(first)
}

pub fn update(source: Source, conn: sqlite.Connection) {
  let res =
    sqlite.exec(
      conn,
      "UPDATE sources 
       SET url = ?, 
           kind = ?, 
           meta = ?,
           task_id = ?,
           updated_at = ? 
       WHERE id = ?",
      [
        source.url |> sqlite.bind,
        encode_kind(source.kind) |> sqlite.bind,
        source.meta |> encode_meta |> sqlite.bind,
        source.task_id |> sqlite.option,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        source.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_kind(kind: SourceKind, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, url, kind, meta, task_id, created_at, updated_at 
     FROM sources 
     WHERE kind = ?;",
    conn,
    [kind |> encode_kind |> sqlite.bind],
    source_decoder(),
  ))

  Ok(items)
}
