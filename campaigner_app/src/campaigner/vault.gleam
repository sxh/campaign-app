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

pub type Stats {
  Stats(
    total_files: Int, 
    md_files: Int, 
    image_files: Int, 
    total_characters: Int,
    vault_path: String
  )
}

pub fn gather_stats(path: String, fs: FileSystem) -> Stats {
  case fs.get_files(path) {
    Ok(files) -> {
      let md_files = list.filter(files, is_markdown)
      let image_files = list.filter(files, is_image)
      let total_chars = count_characters(md_files, fs.read)

      Stats(
        total_files: list.length(files),
        md_files: list.length(md_files),
        image_files: list.length(image_files),
        total_characters: total_chars,
        vault_path: path,
      )
    }
    Error(_) -> Stats(0, 0, 0, 0, path)
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
