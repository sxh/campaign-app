import campaigner/ports/file_system.{type FileSystem, FileSystem}
import simplifile

pub fn real_fs() -> FileSystem {
  FileSystem(
    get_files: simplifile.get_files,
    read: simplifile.read
  )
}
