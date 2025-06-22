import birl
import gleam/dict
import gleam/io
import gleam/string
import gleam/string_tree
import gleamy_lights/premixed
import justin
import youid/uuid

pub type LogLevel {
  Info
  Warn
  Notice
}

fn log_level_to_json(log_level: LogLevel) -> String {
  case log_level {
    Info -> "INFO" |> premixed.bg_blue |> premixed.text_white
    Warn -> "WARN" |> premixed.bg_yellow |> premixed.text_black
    Notice -> "NOTICE" |> premixed.bg_red |> premixed.text_white
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

pub fn trap_info(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: Info) |> write(e |> string.inspect)
      res
    }
    _ -> {
      res
    }
  }
}

pub fn warn(logger: Logger, message: String) {
  Logger(..logger, level: Warn) |> write(message)
}

pub fn notice(logger: Logger, message: String) {
  Logger(..logger, level: Notice) |> write(message)
}

pub fn trap_warn(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: Warn) |> write(e |> string.inspect)
      res
    }
    _ -> {
      res
    }
  }
}

pub fn trap_notice(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: Notice) |> write(e |> string.inspect)
      res
    }
    _ -> {
      res
    }
  }
}

fn write(logger: Logger, message: String) {
  let out =
    string_tree.new()
    |> string_tree.append(birl.utc_now() |> birl.to_naive_time_string() <> " ")
    |> string_tree.append(logger.cid <> " ")
    |> string_tree.append(log_level_to_json(logger.level) <> " ")
    |> string_tree.append(justin.pascal_case(logger.group) <> " ")

  dict.fold(logger.scope, out, fn(acc, key, value) {
    string_tree.append(acc, key <> "=" <> value <> " ")
  })
  |> string_tree.append(message)
  |> string_tree.to_string
  |> io.println
}
