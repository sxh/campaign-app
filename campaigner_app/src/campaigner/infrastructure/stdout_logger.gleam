import campaigner/ports/logger.{type Logger, Logger}
import gleam/io

pub fn new() -> Logger {
  Logger(
    info: fn(msg) { io.println("INFO: " <> msg) },
    error: fn(msg) { io.println("ERROR: " <> msg) }
  )
}
