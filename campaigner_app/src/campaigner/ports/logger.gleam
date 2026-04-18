pub type Logger {
  Logger(
    info: fn(String) -> Nil,
    error: fn(String) -> Nil
  )
}
