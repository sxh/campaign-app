import campaigner/ports/chat_engine.{type ChatEngine, ChatEngine, EngineError}
import gleam/dynamic.{type Dynamic}

@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(bin: String) -> Dynamic

@external(erlang, "os", "cmd")
fn os_cmd(cmd: Dynamic) -> Dynamic

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

pub fn new() -> ChatEngine {
  new_with_executor(fn(cmd) { os_cmd(binary_to_list(cmd)) |> list_to_binary })
}

pub fn new_with_executor(executor: fn(String) -> String) -> ChatEngine {
  ChatEngine(ask: fn(context_path, prompt) {
    let cmd_str =
      "gemini ask --context " <> context_path <> " \"" <> prompt <> "\""
    let output = executor(cmd_str)

    case output {
      "" -> Error(EngineError("Gemini CLI returned no output"))
      _ -> Ok(output)
    }
  })
}
