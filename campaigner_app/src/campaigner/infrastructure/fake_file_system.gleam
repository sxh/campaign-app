import campaigner/ports/file_system.{type FileSystem, FileSystem}
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import simplifile.{Enoent}

pub fn new(files: Dict(String, String)) -> FileSystem {
  FileSystem(
    get_files: fn(path) {
      let keys = dict.keys(files)
      let matches = list.filter(keys, fn(k) { string.starts_with(k, path) })
      case list.is_empty(matches) {
        True -> Error(Enoent)
        False -> Ok(matches)
      }
    },
    read: fn(path) {
      case dict.get(files, path) {
        Ok(content) -> Ok(content)
        Error(_) -> Error(Enoent)
      }
    }
  )
}
