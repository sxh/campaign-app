import gleam/list
import gleam/string
import simplifile

pub fn vault_path() -> String {
  "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault"
}

pub fn note_count(vault_path: String) -> Int {
  do_note_count(vault_path)
}

@target(javascript)
fn do_note_count(_vault_path: String) -> Int {
  0
}

@target(erlang)
fn do_note_count(vault_path: String) -> Int {
  let assert Ok(files) = simplifile.get_files(vault_path)
  list.filter(files, fn(f) { string.ends_with(f, ".md") })
  |> list.length
}
