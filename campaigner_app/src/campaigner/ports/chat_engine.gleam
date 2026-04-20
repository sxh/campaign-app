pub type ChatError {
  EngineError(reason: String)
}

pub type ChatEngine {
  ChatEngine(ask: fn(String, String) -> Result(String, ChatError))
}
