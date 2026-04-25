import gleam/string
import gleeunit
import gleeunit/should
import obsidian_vault

@target(erlang)
import obsidian_vault_erlang

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

@target(javascript)
pub fn note_count_returns_notes_for_given_vault_path_test() {
  Nil
}

@target(erlang)
pub fn note_count_returns_notes_for_given_vault_path_test() {
  let path = obsidian_vault.vault_path()
  let count = obsidian_vault_erlang.note_count(path)
  should.be_true(count > 0)
}
