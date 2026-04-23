import gleeunit
import gleeunit/should
import obsidian_vault

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn vault_path_returns_forgotten_realms_vault_test() {
  obsidian_vault.vault_path()
  |> should.equal(
    "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault/",
  )
}
