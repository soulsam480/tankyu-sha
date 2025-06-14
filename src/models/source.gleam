import birl
import ffi/sqlite
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option}
import gleam/result
import lib/error

pub opaque type Source {
  Source(
    id: Int,
    url: String,
    kind: String,
    meta: Option(String),
    created_at: String,
    updated_at: String,
  )
}

fn source_decoder() -> decode.Decoder(Source) {
  use id <- decode.field("id", decode.int)
  use url <- decode.optional_field("url", "", decode.string)
  use kind <- decode.optional_field("kind", "", decode.string)
  use meta <- decode.optional_field(
    "meta",
    option.None,
    decode.optional(decode.string),
  )
  use created_at <- decode.optional_field("created_at", "", decode.string)
  use updated_at <- decode.optional_field("updated_at", "", decode.string)

  decode.success(Source(id:, url:, kind:, meta:, created_at:, updated_at:))
}

pub fn new() {
  Source(
    id: 0,
    url: "",
    kind: "",
    meta: option.None,
    created_at: birl.utc_now() |> birl.to_iso8601(),
    updated_at: birl.utc_now() |> birl.to_iso8601(),
  )
}

pub fn set_url(source: Source, url: String) {
  Source(..source, url:)
}

pub fn set_kind(source: Source, kind: String) {
  Source(..source, kind:)
}

pub fn set_meta(source: Source, meta: String) {
  Source(..source, meta: option.Some(meta))
}

pub fn create(source: Source, connection: sqlite.Connection) {
  let res =
    sqlite.exec(
      connection,
      "INSERT INTO sources (url, kind, meta, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?)",
      [
        source.url |> sqlite.bind,
        source.kind |> sqlite.bind,
        source.meta |> sqlite.option,
        source.created_at |> sqlite.bind,
        source.updated_at |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn find(id: Int, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, url, kind, meta, created_at, updated_at 
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
           updated_at = ? 
       WHERE id = ?",
      [
        source.url |> sqlite.bind,
        source.kind |> sqlite.bind,
        source.meta |> sqlite.option,
        birl.utc_now() |> birl.to_iso8601() |> sqlite.bind,
        source.id |> sqlite.bind,
      ],
    )

  result.is_ok(res)
}

pub fn of_kind(kind: String, conn: sqlite.Connection) {
  use items <- result.try(sqlite.query(
    "SELECT id, url, kind, meta, created_at, updated_at 
     FROM sources 
     WHERE kind = ?;",
    conn,
    [kind |> sqlite.bind],
    source_decoder(),
  ))

  Ok(items)
}
