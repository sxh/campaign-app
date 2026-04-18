import campaigner/vault
import campaigner/web/views
import lustre/element.{type Element}

pub type DashboardData {
  DashboardData(
    stats: vault.Stats
  )
}

pub fn prepare_dashboard_data(vault_path: vault.VaultPath, ctx: vault.Context) -> Result(DashboardData, vault.VaultError) {
  case vault.gather_stats(vault_path, ctx) {
    Ok(stats) -> Ok(DashboardData(stats))
    Error(err) -> Error(err)
  }
}

pub fn render_dashboard_page(data: DashboardData) -> Element(msg) {
  views.render_dashboard(data.stats)
  |> views.layout("Campaigner Dashboard", _)
}

pub fn render_error_page(error: vault.VaultError) -> Element(msg) {
  let title = case error {
    vault.VaultNotFound(_) -> "Vault Not Found"
    vault.FileReadError(_, _) -> "Read Error"
    vault.InvalidPath(_) -> "Invalid Path"
  }
  views.render_error_page(error)
  |> views.layout(title, _)
}

pub fn render_404_page() -> Element(msg) {
  views.render_404()
  |> views.layout("404 - Not Found", _)
}
