import campaigner/ports/chat_engine.{type ChatEngine, ChatEngine}

pub fn new() -> ChatEngine {
  ChatEngine(
    ask: fn(_context_path, _prompt) {
      // For now, this is a stub that we will implement with shell calls later.
      Ok("Gemini CLI response stub")
    }
  )
}
