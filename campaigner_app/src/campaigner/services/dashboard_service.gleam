import campaigner/vault
import campaigner/web/views
import gleam/int
import lustre/element.{type Element}

pub type DashboardData {
  DashboardData(stats: vault.Stats)
}

pub fn prepare_dashboard_data(
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Result(DashboardData, vault.VaultError) {
  case vault.gather_stats(vault_path, ctx) {
    Ok(stats) -> Ok(DashboardData(stats))
    Error(err) -> Error(err)
  }
}

pub fn ask_vault(
  prompt: String,
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Result(String, String) {
  let path_str = vault.vault_path_to_string(vault_path)
  case ctx.chat.ask(path_str, prompt) {
    Ok(response) -> Ok(response)
    Error(_err) -> {
      Error("Failed to communicate with chat engine")
    }
  }
}

pub fn render_dashboard_page(data: DashboardData) -> Element(msg) {
  to_dashboard_view_model(data.stats)
  |> views.render_dashboard
  |> views.layout("Campaigner Dashboard", _)
}

pub fn render_chat_page(vm: views.ChatViewModel) -> Element(msg) {
  views.render_chat(vm)
  |> views.layout("Chat with your Vault", _)
}

pub fn to_dashboard_view_model(stats: vault.Stats) -> views.DashboardViewModel {
  views.DashboardViewModel(
    vault_path: vault.vault_path_to_string(vault.get_vault_path(stats)),
    total_files: int.to_string(vault.get_total_files(stats)),
    md_files: int.to_string(vault.get_md_files(stats)),
    total_characters: int.to_string(vault.get_total_characters(stats)),
    image_files: int.to_string(vault.get_image_files(stats)),
    notes_message: get_notes_message(vault.get_md_files(stats)),
    chars_message: get_chars_message(vault.get_total_characters(stats)),
  )
}

pub fn render_error_page(error: vault.VaultError) -> Element(msg) {
  let #(title, message) = case error {
    vault.VaultNotFound(p) -> #(
      "Vault Not Found",
      "We couldn't find your Obsidian vault at: " <> p,
    )
    vault.FileReadError(p, _) -> #(
      "Read Error",
      "There was an error reading a file in your vault: " <> p,
    )
    vault.InvalidPath(reason) -> #(
      "Invalid Path",
      "The provided vault path is invalid: " <> reason,
    )
    vault.Timeout(reason) -> #("Timeout", "The operation timed out: " <> reason)
  }

  let vm = views.ErrorViewModel(title: title, message: message)

  views.render_error_page(vm)
  |> views.layout(title, _)
}

pub fn render_404_page() -> Element(msg) {
  views.render_404()
  |> views.layout("404 - Not Found", _)
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
