import campaigner_app.{InitFlags}
import gleam/bit_array
import lustre
import obsidian_vault
import opencode_session

pub fn main() {
  let app =
    lustre.application(
      campaigner_app.init,
      campaigner_app.update,
      campaigner_app.view,
    )
  let vault_path = obsidian_vault.vault_path()
  let vault_encoded =
    bit_array.base64_encode(bit_array.from_string(vault_path), False)
  let url = opencode_session.session_iframe_url(vault_encoded)
  let flags = InitFlags(url)
  let assert Ok(_) = lustre.start(app, "#app", flags)
  Nil
}
