import gleam/string
import gleeunit
import gleeunit/should
import obsidian_vault

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn vault_path_returns_forgotten_realms_vault_without_trailing_slash_test() {
  obsidian_vault.vault_path()
  |> should.equal(
    "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault",
  )
}

pub fn vault_path_has_no_trailing_slash_test() {
  let path = obsidian_vault.vault_path()
  let has_trailing_slash = string.ends_with(path, "/")
  has_trailing_slash |> should.be_false
}
