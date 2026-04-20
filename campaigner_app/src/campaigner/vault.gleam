import campaigner/ports/chat_engine.{type ChatEngine}
import campaigner/ports/file_system.{type FileSystem}
import campaigner/ports/logger.{type Logger}
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile.{type FileError}

pub type FileCount =
  Int

pub type CharacterCount =
  Int

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
  Context(fs: FileSystem, logger: Logger, chat: ChatEngine, timeout_ms: Int)
}

pub type VaultError {
  VaultNotFound(path: String)
  FileReadError(path: String, error: FileError)
  InvalidPath(reason: String)
  Timeout(file: String)
}

pub opaque type Stats {
  Stats(
    total_files: FileCount,
    md_files: FileCount,
    image_files: FileCount,
    total_characters: CharacterCount,
    vault_path: VaultPath,
  )
}

// Getters for Stats
pub fn get_total_files(stats: Stats) -> FileCount {
  stats.total_files
}

pub fn get_md_files(stats: Stats) -> FileCount {
  stats.md_files
}

pub fn get_image_files(stats: Stats) -> FileCount {
  stats.image_files
}

pub fn get_total_characters(stats: Stats) -> CharacterCount {
  stats.total_characters
}

pub fn get_vault_path(stats: Stats) -> VaultPath {
  stats.vault_path
}

// Internal constructor for gather_stats
fn new_stats(
  total_files: FileCount,
  md_files: FileCount,
  image_files: FileCount,
  total_characters: CharacterCount,
  vault_path: VaultPath,
) -> Stats {
  Stats(total_files, md_files, image_files, total_characters, vault_path)
}

pub fn gather_stats(path: VaultPath, ctx: Context) -> Result(Stats, VaultError) {
  let path_str = vault_path_to_string(path)

  use files <- result.try(
    ctx.fs.get_files(path_str)
    |> result.map_error(fn(_) { VaultNotFound(path_str) }),
  )

  let md_files = list.filter(files, is_markdown)
  let image_files = list.filter(files, is_image)

  use total_chars <- result.try(count_characters(
    md_files,
    ctx.fs.read,
    ctx.timeout_ms,
  ))

  ctx.logger.info("Scanned vault", [
    #("path", path_str),
    #("md_files", int.to_string(list.length(md_files))),
  ])

  Ok(new_stats(
    list.length(files),
    list.length(md_files),
    list.length(image_files),
    total_chars,
    path,
  ))
}

fn count_characters(
  files: List(String),
  read_file: fn(String) -> Result(String, FileError),
  timeout: Int,
) -> Result(Int, VaultError) {
  // Process in chunks of 50 to avoid overwhelming the BEAM for huge vaults
  groups_of(files, 50)
  |> list.fold(Ok(0), fn(acc, chunk) {
    use current_total <- result.try(acc)
    use chunk_total <- result.try(process_chunk(chunk, read_file, timeout))
    Ok(current_total + chunk_total)
  })
}
fn groups_of(list: List(a), count: Int) -> List(List(a)) {
  case list {
    [] -> []
    _ -> {
      let #(first, rest) = list.split(list, count)
      [first, ..groups_of(rest, count)]
    }
  }
}
pub fn sized_chunk(list: List(a), count: Int) -> List(List(a)) {
  groups_of(list, count)
}



fn process_chunk(
  chunk: List(String),
  read_file: fn(String) -> Result(String, FileError),
  timeout: Int,
) -> Result(Int, VaultError) {
  let self = process.new_subject()

  chunk
  |> list.each(fn(file) {
    process.spawn(fn() { process.send(self, #(file, read_file(file))) })
  })

  list.fold(chunk, Ok(0), fn(acc, _) {
    use current_total <- result.try(acc)
    case process.receive(self, timeout) {
      Ok(#(_file, Ok(content))) -> Ok(current_total + string.length(content))
      Ok(#(file, Error(err))) -> Error(FileReadError(file, err))
      Error(_) -> Error(Timeout(""))
      // Timeout while reading file
    }
  })
}

pub fn is_markdown(file: String) -> Bool {
  string.ends_with(file, ".md")
}

pub fn is_image(file: String) -> Bool {
  string.ends_with(file, ".png")
  || string.ends_with(file, ".jpg")
  || string.ends_with(file, ".jpeg")
}
