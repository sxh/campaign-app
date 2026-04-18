import campaigner/vault

pub type Config {
  Config(vault_path: vault.VaultPath)
}

pub type ConfigError {
  EnvironmentVariableMissing(name: String)
  InvalidConfigPath(reason: String)
}

@external(erlang, "os", "getenv")
fn get_env_ffi(name: String) -> Result(String, Nil)

pub fn load() -> Result(Config, ConfigError) {
  let name = "CAMPAIGNER_VAULT_PATH"
  let path_str = case get_env_ffi(name) {
    Ok(p) -> p
    Error(_) -> "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/CthulhuVault/"
  }
  
  case vault.vault_path_from_string(path_str) {
    Ok(vault_path) -> Ok(Config(vault_path: vault_path))
    Error(err) -> Error(InvalidConfigPath(string_from_vault_error(err)))
  }
}

fn string_from_vault_error(err: vault.VaultError) -> String {
  case err {
    vault.VaultNotFound(p) -> "Path not found: " <> p
    vault.FileReadError(p, _) -> "Read error: " <> p
    vault.InvalidPath(reason) -> reason
  }
}
