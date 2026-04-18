import gleam/http/response.{type Response}
import gleam/http/request.{type Request}
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

pub fn router(req: Request(t), vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case parse_route(request.path_segments(req)) {
    Dashboard -> serve_dashboard(vault_path, ctx)
    Chat -> serve_chat(req, vault_path, ctx)
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

pub fn serve_chat(req: Request(t), vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  // For now, returning a basic form response.
  // Real implementation will handle POST and service.ask_vault
  "Chat Facility: GET to view, POST to ask"
  |> bytes_tree.from_string
  |> response.set_body(response.new(200), _)
}

pub fn serve_404() -> Response(BytesTree) {
  service.render_404_page()
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}
