import campaigner/ports/file_system.{type FileSystem, FileSystem}
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import simplifile.{type FileError, Enoent}

pub fn new(files: Dict(String, Result(String, FileError))) -> FileSystem {
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
        Ok(res) -> res
        Error(_) -> Error(Enoent)
      }
    },
  )
}

pub fn from_contents(files: Dict(String, String)) -> FileSystem {
  files
  |> dict.to_list
  |> list.map(fn(pair) { #(pair.0, Ok(pair.1)) })
  |> dict.from_list
  |> new
}
