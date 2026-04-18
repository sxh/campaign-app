import gleam/list
import gleam/string
import gleam/result
import gleam/erlang/process
import campaigner/ports/file_system.{type FileSystem}
import simplifile.{type FileError}

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

pub opaque type Stats {
  Stats(
    total_files: Int, 
    md_files: Int, 
    image_files: Int, 
    total_characters: Int,
    vault_path: VaultPath
  )
}

// Getters for Stats
pub fn get_total_files(stats: Stats) -> Int { stats.total_files }
pub fn get_md_files(stats: Stats) -> Int { stats.md_files }
pub fn get_image_files(stats: Stats) -> Int { stats.image_files }
pub fn get_total_characters(stats: Stats) -> Int { stats.total_characters }
pub fn get_vault_path(stats: Stats) -> VaultPath { stats.vault_path }

// Internal constructor for gather_stats
fn new_stats(
  total_files: Int, 
  md_files: Int, 
  image_files: Int, 
  total_characters: Int,
  vault_path: VaultPath
) -> Stats {
  Stats(total_files, md_files, image_files, total_characters, vault_path)
}

pub fn gather_stats(path: VaultPath, ctx: Context) -> Result(Stats, VaultError) {
  let path_str = vault_path_to_string(path)
  
  use files <- result.try(
    ctx.fs.get_files(path_str)
    |> result.map_error(fn(_) { VaultNotFound(path_str) })
  )

  let md_files = list.filter(files, is_markdown)
  let image_files = list.filter(files, is_image)
  let total_chars = count_characters(md_files, ctx.fs.read)

  Ok(new_stats(
    list.length(files),
    list.length(md_files),
    list.length(image_files),
    total_chars,
    path,
  ))
}

fn count_characters(files: List(String), read_file: fn(String) -> Result(String, FileError)) -> Int {
  let self = process.new_subject()
  
  files
  |> list.each(fn(file) {
    process.spawn(fn() {
      process.send(self, get_file_char_count(file, read_file))
    })
  })
  
  list.fold(files, 0, fn(acc, _) {
    // 5 second timeout per file read to prevent hanging
    case process.receive(self, 5000) {
      Ok(count) -> acc + count
      Error(_) -> acc
    }
  })
}

fn get_file_char_count(file: String, read_file: fn(String) -> Result(String, FileError)) -> Int {
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
