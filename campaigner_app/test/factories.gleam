import campaigner/vault
import campaigner/infrastructure/fake_file_system
import gleam/dict

pub fn stats() -> vault.Stats {
  let path_str = "/test/vault"
  let assert Ok(path) = vault.vault_path_from_string(path_str)
  let files = dict.from_list([#(path_str <> "/dummy.md", "")])
  let fs = fake_file_system.new(files)
  let ctx = vault.Context(fs: fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)
  stats
}

pub fn context() -> vault.Context {
  vault.Context(fs: fake_file_system.new(dict.new()))
}

pub fn vault_path(path_str: String) -> vault.VaultPath {
  let assert Ok(path) = vault.vault_path_from_string(path_str)
  path
}
