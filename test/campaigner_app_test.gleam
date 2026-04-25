import campaigner_app
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import obsidian_vault
import opencode_session

pub fn main() -> Nil {
  gleeunit.main()
}

fn test_iframe_url() -> String {
  opencode_session.session_iframe_url(
    "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0",
  )
}

pub fn init_stores_opencode_iframe_url_in_model_test() {
  let expected_url = test_iframe_url()
  let flags = campaigner_app.InitFlags(expected_url, 42)
  let #(model, _eff) = campaigner_app.init(flags)
  model.opencode_iframe_url |> should.equal(expected_url)
  model.note_count |> should.equal(42)
}

pub fn view_contains_iframe_test() {
  let model = campaigner_app.Model("http://example.com/iframe", 10)
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "iframe") |> should.be_true
}

pub fn update_noop_returns_model_unchanged_test() {
  let model = campaigner_app.Model("http://example.com/", 5)
  let #(updated, _eff) = campaigner_app.update(model, campaigner_app.NoOp)
  updated.opencode_iframe_url |> should.equal("http://example.com/")
  updated.note_count |> should.equal(5)
}

pub fn view_always_has_vault_pane_test() {
  let model = campaigner_app.Model("http://example.com/", 100)
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "Vault") |> should.be_true
}

pub fn vault_encoded_matches_correct_base64_for_vault_path_test() {
  let path = obsidian_vault.vault_path()
  let expected_encoded =
    "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0"
  let vault_path_has_no_trailing_slash = !string.ends_with(path, "/")
  vault_path_has_no_trailing_slash |> should.be_true
  path
  |> should.equal(
    "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault",
  )
  let expected_url = "http://127.0.0.1:14096/" <> expected_encoded <> "/session"
  opencode_session.session_iframe_url(expected_encoded)
  |> should.equal(expected_url)
}
