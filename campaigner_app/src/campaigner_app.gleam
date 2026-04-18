import gleam/io
import gleam/list
import gleam/http/response.{type Response}
import gleam/http/request
import gleam/bytes_tree.{type BytesTree}
import mist
import lustre/element
import campaigner/vault
import campaigner/web/views

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

fn serve_dashboard(vault_path: String) -> Response(BytesTree) {
  let stats = vault.gather_stats(vault_path, vault.real_fs())
  views.render_dashboard(stats)
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(200), _)
}

fn serve_404() -> Response(BytesTree) {
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
