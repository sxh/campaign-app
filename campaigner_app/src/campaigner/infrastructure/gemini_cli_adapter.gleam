import campaigner/ports/chat_engine.{type ChatEngine, ChatEngine, EngineError}
import gleam/dynamic.{type Dynamic}

@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(bin: String) -> Dynamic

@external(erlang, "os", "cmd")
fn os_cmd(cmd: Dynamic) -> Dynamic

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

pub fn new() -> ChatEngine {
  ChatEngine(
    ask: fn(context_path, prompt) {
      // Construct the Gemini CLI command.
      // We assume 'gemini' is in the PATH and it takes --context and the prompt.
      // NOTE: This assumes prompt and context_path are safe for shell execution.
      // In a production app, we should escape these.
      let cmd_str = "gemini ask --context " <> context_path <> " \"" <> prompt <> "\""
      
      let res = os_cmd(binary_to_list(cmd_str))
      let output = list_to_binary(res)
      
      case output {
        "" -> Error(EngineError("Gemini CLI returned no output"))
        _ -> Ok(output)
      }
    }
  )
}
