import campaigner_app.{InitFlags}
import lustre
import obsidian_vault
import opencode_session

@target(javascript)
@external(javascript, "./electron_preload_ffi.mjs", "encode_base64")
fn encode_base64(str: String) -> String

@target(erlang)
fn encode_base64(_str: String) -> String {
  panic as "encode_base64 is only available on JavaScript target"
}

pub fn main() {
  let app =
    lustre.application(
      campaigner_app.init,
      campaigner_app.update,
      campaigner_app.view,
    )
  let vault_path = obsidian_vault.vault_path()
  let vault_encoded = encode_base64(vault_path)
  let url = opencode_session.session_iframe_url(vault_encoded)
  let flags = InitFlags(url)
  let assert Ok(_) = lustre.start(app, "#app", flags)
  Nil
}
