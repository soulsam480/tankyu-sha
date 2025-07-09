import birl
import gleam/dict
import gleam/string
import gleam/string_tree
import justin
import logging
import youid/uuid

pub type Logger {
  Logger(
    group: String,
    cid: String,
    level: logging.LogLevel,
    scope: dict.Dict(String, String),
  )
}

pub fn new(group: String) {
  // NOTE: this is called here because the erlang logger is configured per process
  logging.configure()

  Logger(
    group: group,
    cid: uuid.v4_string(),
    level: logging.Info,
    scope: dict.new(),
  )
}

pub fn with_scope(logger: Logger, scope: dict.Dict(String, String)) {
  Logger(..logger, scope:)
}

pub fn info(logger: Logger, message: String) {
  Logger(..logger, level: logging.Info) |> write(message)
}

pub fn trap_info(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: logging.Info) |> write(e |> string.inspect)
      res
    }
    _ -> {
      res
    }
  }
}

pub fn warn(logger: Logger, message: String) {
  Logger(..logger, level: logging.Warning) |> write(message)
}

pub fn error(logger: Logger, message: String) {
  Logger(..logger, level: logging.Error) |> write(message)
}

pub fn trap_warn(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: logging.Warning) |> write(e |> string.inspect)
      res
    }
    _ -> {
      res
    }
  }
}

pub fn trap_error(res: Result(a, b), logger: Logger) {
  case res {
    Error(e) -> {
      Logger(..logger, level: logging.Error) |> write(e |> string.inspect)
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
    |> string_tree.append(justin.pascal_case(logger.group) <> " ")

  dict.fold(logger.scope, out, fn(acc, key, value) {
    string_tree.append(acc, key <> "=" <> value <> " ")
  })
  |> string_tree.append(message)
  |> string_tree.to_string
  |> logging.log(logger.level, _)
}
