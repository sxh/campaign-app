import gleam/list
import gleam/string
import simplifile.{type FileError}

pub type FileSystem {
  FileSystem(
    get_files: fn(String) -> Result(List(String), FileError),
    read: fn(String) -> Result(String, FileError)
  )
}

pub fn real_fs() -> FileSystem {
  FileSystem(
    get_files: simplifile.get_files,
    read: simplifile.read
  )
}

pub opaque type VaultPath {
  VaultPath(path: String)
}

pub fn vault_path_from_string(path: String) -> Result(VaultPath, VaultError) {
  let trimmed = string.trim(path)
  case string.is_empty(trimmed) {
    True -> Error(InvalidPath("Path cannot be empty"))
    False -> Ok(VaultPath(trimmed))
  }
}

pub fn vault_path_to_string(path: VaultPath) -> String {
  path.path
}

pub type Context {
  Context(fs: FileSystem)
}

pub type VaultError {
  VaultNotFound(path: String)
  FileReadError(path: String, error: FileError)
  InvalidPath(reason: String)
}

pub type Stats {
  Stats(
    total_files: Int, 
    md_files: Int, 
    image_files: Int, 
    total_characters: Int,
    vault_path: VaultPath
  )
}

pub fn gather_stats(path: VaultPath, ctx: Context) -> Result(Stats, VaultError) {
  let path_str = vault_path_to_string(path)
  case ctx.fs.get_files(path_str) {
    Ok(files) -> {
      let md_files = list.filter(files, is_markdown)
      let image_files = list.filter(files, is_image)
      let total_chars = count_characters(md_files, ctx.fs.read)

      Ok(Stats(
        total_files: list.length(files),
        md_files: list.length(md_files),
        image_files: list.length(image_files),
        total_characters: total_chars,
        vault_path: path,
      ))
    }
    Error(_) -> Error(VaultNotFound(path_str))
  }
}

pub fn count_characters(files: List(String), read_file: fn(String) -> Result(String, FileError)) -> Int {
  list.fold(files, 0, fn(acc, file) {
    acc + get_file_char_count(file, read_file)
  })
}

pub fn get_file_char_count(file: String, read_file: fn(String) -> Result(String, FileError)) -> Int {
  case read_file(file) {
    Ok(content) -> string.length(content)
    Error(_) -> 0
  }
}

pub fn is_markdown(file: String) -> Bool {
  string.ends_with(file, ".md")
}

pub fn is_image(file: String) -> Bool {
  string.ends_with(file, ".png") || string.ends_with(file, ".jpg") || string.ends_with(file, ".jpeg")
}
