import campaigner/vault

pub type Config {
  Config(vault_path: vault.VaultPath)
}

@external(erlang, "os", "getenv")
fn get_env_ffi(name: String) -> Result(String, Nil)

pub fn load() -> Config {
  let name = "CAMPAIGNER_VAULT_PATH"
  let path_str = case get_env_ffi(name) {
    Ok(p) -> p
    Error(_) -> "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/CthulhuVault/"
  }
  Config(vault_path: vault.vault_path_from_string(path_str))
}
