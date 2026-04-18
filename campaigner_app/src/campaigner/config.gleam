import campaigner/vault
import campaigner/config/defaults
import gleam/dynamic.{type Dynamic}

pub type Config {
  Config(vault_path: vault.VaultPath)
}

pub type ConfigError {
  EnvironmentVariableMissing(name: String)
  InvalidConfigPath(reason: String)
}

@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(bin: String) -> Dynamic

@external(erlang, "os", "getenv")
fn get_env_ffi(name: Dynamic) -> Dynamic

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(list: Dynamic) -> String

@external(erlang, "erlang", "is_list")
fn is_list(val: Dynamic) -> Bool

pub fn load() -> Result(Config, ConfigError) {
  let name = "CAMPAIGNER_VAULT_PATH"
  let res = get_env_ffi(binary_to_list(name))
  
  let path_str = case is_list(res) {
    True -> list_to_binary(res)
    False -> defaults.vault_path
  }
  
  case vault.vault_path_from_string(path_str) {
    Ok(vault_path) -> Ok(Config(vault_path: vault_path))
    Error(err) -> Error(InvalidConfigPath(string_from_vault_error(err)))
  }
}

pub fn string_from_vault_error(err: vault.VaultError) -> String {
  case err {
    vault.VaultNotFound(p) -> "Path not found: " <> p
    vault.FileReadError(p, _) -> "Read error: " <> p
    vault.InvalidPath(reason) -> reason
  }
}
