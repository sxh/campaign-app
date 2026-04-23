import campaigner_app.{InitFlags}
import electron_preload
import lustre
import obsidian_vault

pub fn main() {
  let app =
    lustre.application(
      campaigner_app.init,
      campaigner_app.update,
      campaigner_app.view,
    )
  let vault_path = obsidian_vault.vault_path()
  let vault_encoded = electron_preload.encode_base64(vault_path)
  let flags = InitFlags(vault_encoded, vault_path)
  let assert Ok(_) = lustre.start(app, "#app", flags)
  Nil
}
