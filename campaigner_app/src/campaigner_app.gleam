import gleam/io
import gleam/list
import gleam/string
import gleam/int
import gleam/http/response
import gleam/http/request.{type Request}
import gleam/bytes_tree
import mist
import lustre/element
import lustre/element/html
import simplifile

pub fn main() {
  let vault_path = "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/CthulhuVault/"
  
  io.println("Starting Campaigner App on http://localhost:8000")
  
  let assert Ok(_) =
    mist.new(fn(req: Request(mist.Connection)) {
      case request.path_segments(req) {
        [] -> {
          let stats = gather_stats(vault_path)
          render_dashboard(stats)
          |> element.to_string
          |> bytes_tree.from_string
          |> mist.Bytes
          |> response.set_body(response.new(200), _)
        }
        _ -> 
          "Not Found"
          |> bytes_tree.from_string
          |> mist.Bytes
          |> response.set_body(response.new(404), _)
      }
    })
    |> mist.port(8000)
    |> mist.start

  // Keep the process alive
  process_sleep_forever()
}

@external(erlang, "timer", "sleep")
fn timer_sleep(ms: Int) -> Nil

fn process_sleep_forever() {
  timer_sleep(1000 * 60 * 60 * 24)
  process_sleep_forever()
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

pub fn gather_stats(path: String) -> Stats {
  case simplifile.get_files(path) {
    Ok(files) -> {
      let md_files = list.filter(files, fn(f) { string.ends_with(f, ".md") })
      let image_files = list.filter(files, fn(f) { 
        string.ends_with(f, ".png") || string.ends_with(f, ".jpg") || string.ends_with(f, ".jpeg") 
      })
      
      let total_chars = list.fold(md_files, 0, fn(acc, file) {
        case simplifile.read(file) {
          Ok(content) -> acc + string.length(content)
          Error(_) -> acc
        }
      })

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

pub fn render_dashboard(stats: Stats) {
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
    html.footer([], [
      element.text("Built with Gleam, Lustre, and Mist.")
    ])
  ])
}
