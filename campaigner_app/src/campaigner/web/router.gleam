import gleam/http/response.{type Response}
import gleam/bytes_tree.{type BytesTree}
import campaigner/vault
import campaigner/web/views
import lustre/element

pub fn router(path: List(String), vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case path {
    [] -> serve_dashboard(vault_path, ctx)
    _ -> serve_404()
  }
}

pub fn serve_dashboard(vault_path: vault.VaultPath, ctx: vault.Context) -> Response(BytesTree) {
  case vault.gather_stats(vault_path, ctx) {
    Ok(stats) -> {
      views.render_dashboard(stats)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(200), _)
    }
    Error(err) -> {
      let msg = case err {
        vault.VaultNotFound(p) -> "Vault not found at: " <> p
        vault.FileReadError(p, _) -> "Error reading file: " <> p
      }
      msg
      |> bytes_tree.from_string
      |> response.set_body(response.new(500), _)
    }
  }
}

pub fn serve_404() -> Response(BytesTree) {
  "Not Found"
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}
