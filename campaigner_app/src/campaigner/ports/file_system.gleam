import simplifile.{type FileError}

pub type FileSystem {
  FileSystem(
    get_files: fn(String) -> Result(List(String), FileError),
    read: fn(String) -> Result(String, FileError),
  )
}
