pub type LogFields = List(#(String, String))

pub type Logger {
  Logger(
    info: fn(String, LogFields) -> Nil,
    error: fn(String, LogFields) -> Nil
  )
}
