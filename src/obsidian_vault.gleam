import gleam/list
import gleam/string
import simplifile

pub fn vault_path() -> String {
  "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault"
}

pub fn note_count(vault_path: String) -> Int {
  let assert Ok(files) = simplifile.get_files(vault_path)
  files
  |> list.filter(fn(f) { string.ends_with(f, ".md") })
  |> list.length
}
