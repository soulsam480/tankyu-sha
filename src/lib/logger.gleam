import birl
import gleam/dict
import gleam/io
import gleam/string
import gleam/string_tree
import youid/uuid

pub type LogLevel {
  Info
  Warn
  Notice
}

fn log_level_to_json(log_level: LogLevel) -> String {
  case log_level {
    Info -> "info"
    Warn -> "warn"
    Notice -> "notice"
  }
}

pub type Logger {
  Logger(
    group: String,
    cid: String,
    level: LogLevel,
    scope: dict.Dict(String, String),
  )
}

pub fn new(group: String) {
  Logger(group: group, cid: uuid.v4_string(), level: Info, scope: dict.new())
}

pub fn with_scope(logger: Logger, scope: dict.Dict(String, String)) {
  Logger(..logger, scope:)
}

pub fn info(logger: Logger, message: String) {
  Logger(..logger, level: Info) |> write(message)
}

pub fn warn(logger: Logger, message: String) {
  Logger(..logger, level: Warn) |> write(message)
}

pub fn notice(logger: Logger, message: String) {
  Logger(..logger, level: Notice) |> write(message)
}

fn write(logger: Logger, message: String) {
  let out =
    string_tree.new()
    |> string_tree.append(birl.utc_now() |> birl.to_naive_time_string() <> " ")
    |> string_tree.append(logger.cid <> " ")
    |> string_tree.append(
      log_level_to_json(logger.level) |> string.uppercase <> " ",
    )
    |> string_tree.append(string.uppercase(logger.group) <> " ")

  dict.fold(logger.scope, out, fn(acc, key, value) {
    string_tree.append(acc, key <> "=" <> value <> " ")
  })
  |> string_tree.append(message)
  |> string_tree.to_string
  |> io.println
}
