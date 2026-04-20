import campaigner/ports/chat_engine.{type ChatEngine, ChatEngine, EngineError}
import gleam/dynamic.{type Dynamic}
import gleam/string

@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(bin: String) -> Dynamic

@external(erlang, "os", "cmd")
fn os_cmd(cmd: Dynamic) -> Dynamic

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

pub fn new() -> ChatEngine {
  new_with_executor(shell_executor)
}

pub fn shell_executor(cmd: String) -> String {
  os_cmd(binary_to_list(cmd)) |> list_to_binary
}

fn escape_shell_argument(arg: String) -> String {
  // Escape single quotes by replacing ' with '\''
  // In a single-quoted shell string, the sequence '\'' ends the current string,
  // adds a literal single quote, and starts a new single-quoted string
  string.replace(arg, "'", "'\\''")
}

fn is_error_output(output: String) -> Bool {
  string.starts_with(output, "Unknown argument:")
  || string.starts_with(output, "Usage:")
  || string.starts_with(output, "error:")
  || string.starts_with(output, "Error:")
}

pub fn new_with_executor(executor: fn(String) -> String) -> ChatEngine {
  ChatEngine(ask: fn(context_path, prompt) {
    let escaped_context = escape_shell_argument(context_path)
    let escaped_prompt = escape_shell_argument(prompt)
    let cmd_str =
      "gemini --prompt '"
      <> escaped_prompt
      <> "' --include-directories '"
      <> escaped_context
      <> "' --output-format text 2>&1"
    let output = executor(cmd_str)

    case output {
      "" -> Error(EngineError("Gemini CLI returned no output"))
      _ -> {
        case is_error_output(output) {
          True -> Error(EngineError("Gemini CLI error: " <> output))
          False -> Ok(output)
        }
      }
    }
  })
}
