import gleam/http/response.{type Response}
import gleam/bytes_tree.{type BytesTree}
import campaigner/vault
import campaigner/services/dashboard_service as service
import lustre/element

pub type Route {
  Dashboard
  Chat
  NotFound
}

pub fn parse_route(path: List(String)) -> Route {
  case path {
    [] -> Dashboard
    ["chat"] -> Chat
    _ -> NotFound
  }
}

pub fn router(path: List(String), vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case parse_route(path) {
    Dashboard -> serve_dashboard(vault_path, ctx)
    Chat -> serve_chat(vault_path, ctx)
    NotFound -> serve_404()
  }
}

pub fn serve_dashboard(vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case service.prepare_dashboard_data(vault_path, ctx) {
    Ok(data) -> {
      service.render_dashboard_page(data)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(200), _)
    }
    Error(err) -> {
      service.render_error_page(err)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(500), _)
    }
  }
}

pub fn serve_chat(_vault_path: vault.VaultPath, _ctx: vault.Context) -> Response(BytesTree) {
  // For now, return a placeholder for the chat page
  "Chat Facility Coming Soon"
  |> bytes_tree.from_string
  |> response.set_body(response.new(200), _)
}

pub fn serve_404() -> Response(BytesTree) {
  service.render_404_page()
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}
