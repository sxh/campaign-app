import gleam/http/response.{type Response}
import gleam/bytes_tree.{type BytesTree}
import campaigner/vault
import campaigner/services/dashboard_service as service
import lustre/element

pub fn router(path: List(String), vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case path {
    [] -> serve_dashboard(vault_path, ctx)
    _ -> serve_404()
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

pub fn serve_404() -> Response(BytesTree) {
  service.render_404_page()
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}
