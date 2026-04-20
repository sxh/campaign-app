import campaigner/config/defaults
import campaigner/vault
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
  load_with_env(fn(name) {
    let res = get_env_ffi(binary_to_list(name))
    case is_list(res) {
      True -> Ok(list_to_binary(res))
      False -> Error(Nil)
    }
  })
}

pub fn load_with_env(
  get_env: fn(String) -> Result(String, Nil),
) -> Result(Config, ConfigError) {
  let name = "CAMPAIGNER_VAULT_PATH"
  let path_str = case get_env(name) {
    Ok(p) -> p
    Error(_) -> defaults.vault_path
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
    vault.VaultAccessError(p, _) -> "Vault access error: " <> p
    vault.InvalidPath(reason) -> reason
    vault.Timeout(file) -> "Timeout reading file: " <> file
  }
}

pub fn is_valid_vault_path_format(path: String) -> Bool {
  case path {
    "" -> False
    _ -> True
  }
}
