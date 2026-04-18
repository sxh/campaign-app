import gleam/io
import gleam/list
import gleam/string
import gleam/int
import gleam/http/response.{type Response}
import gleam/http/request
import gleam/bytes_tree.{type BytesTree}
import mist
import lustre/element
import lustre/element/html
import simplifile.{type FileError}

pub const default_vault_path = "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/CthulhuVault/"

pub fn main() {
  io.println("Starting Campaigner App on http://localhost:8000")
  let assert Ok(_) =
    mist.new(handle_connection(_, default_vault_path))
    |> mist.port(8000)
    |> mist.start
  process_sleep_forever()
}

pub fn handle_connection(req: request.Request(t), vault_path: String) -> response.Response(mist.ResponseData) {
  router(request.path_segments(req), vault_path)
  |> response.map(mist.Bytes)
}

pub fn router(path: List(String), vault_path: String) -> Response(BytesTree) {
  case path {
    [] -> serve_dashboard(vault_path)
    _ -> serve_404()
  }
}

pub fn serve_dashboard(vault_path: String) -> Response(BytesTree) {
  let stats = gather_stats(vault_path, real_fs())
  render_dashboard(stats)
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(200), _)
}

pub fn serve_404() -> Response(BytesTree) {
  "Not Found"
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60)
  process_sleep_forever()
}

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

pub fn render_dashboard(stats: Stats) {
  let notes_msg = get_notes_message(stats.md_files)
  let char_msg = get_chars_message(stats.total_characters)

  html.div([], [
    html.h1([], [element.text("Campaigner Dashboard")]),
    html.p([], [element.text("Hello World from Lustre!")]),
    html.h2([], [element.text("Obsidian Vault Stats")]),
    html.ul([], [
      html.li([], [
        element.text("Vault Path: "),
        html.code([], [element.text(stats.vault_path)])
      ]),
      html.li([], [
        element.text("Total Files: "),
        element.text(int.to_string(stats.total_files))
      ]),
      html.li([], [
        element.text("Markdown Notes: "),
        element.text(int.to_string(stats.md_files))
      ]),
      html.li([], [
        element.text("Total Characters in Notes: "),
        element.text(int.to_string(stats.total_characters))
      ]),
      html.li([], [
        element.text("Images: "),
        element.text(int.to_string(stats.image_files))
      ])
    ]),
    html.p([], [element.text(notes_msg)]),
    html.p([], [element.text(char_msg)]),
    html.footer([], [
      element.text("Built with Gleam, Lustre, and Mist.")
    ])
  ])
}

pub fn get_notes_message(count: Int) -> String {
  case count > 0 {
    True -> "You have some notes!"
    False -> "No notes found."
  }
}

pub fn get_chars_message(count: Int) -> String {
  case count > 1000 {
    True -> "Wow, that's a lot of writing!"
    False -> "Keep writing!"
  }
}
