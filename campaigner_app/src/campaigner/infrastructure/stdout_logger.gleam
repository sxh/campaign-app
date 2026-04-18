import campaigner/ports/logger.{type LogFields, type Logger, Logger}
import gleam/io
import gleam/list
import gleam/string

pub fn new() -> Logger {
  Logger(
    info: fn(msg, fields) {
      io.println("INFO: " <> msg <> " " <> format_fields(fields))
    },
    error: fn(msg, fields) {
      io.println("ERROR: " <> msg <> " " <> format_fields(fields))
    },
  )
}

fn format_fields(fields: LogFields) -> String {
  case fields {
    [] -> ""
    _ ->
      "["
      <> list.map(fields, fn(f) { f.0 <> "=" <> f.1 })
      |> string.join(", ")
      <> "]"
  }
}
