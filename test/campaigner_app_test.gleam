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

fn test_vault_path() -> String {
  "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault/"
}

fn test_vault_encoded() -> String {
  "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0Lw=="
}

fn test_model() -> campaigner_app.Model {
  campaigner_app.Model(opencode_session.Loading, test_vault_encoded())
}

pub fn init_returns_loading_model_test() {
  let flags = campaigner_app.InitFlags(test_vault_encoded(), test_vault_path())
  let #(model, _eff) = campaigner_app.init(flags, fn(_, _, _, _) { Nil })
  model.vault_encoded |> should.equal(test_vault_encoded())
  model.state |> should.equal(opencode_session.Loading)
}

pub fn update_session_ready_transitions_to_ready_test() {
  let model = test_model()
  let result =
    campaigner_app.update(model, campaigner_app.SessionReady("ses_abc123"))
  let expected_url =
    opencode_session.session_iframe_url(test_vault_encoded(), "ses_abc123")
  result.0.state |> should.equal(opencode_session.Ready(expected_url))
}

pub fn update_session_error_transitions_to_error_test() {
  let model = test_model()
  let result =
    campaigner_app.update(
      model,
      campaigner_app.SessionError("connection failed"),
    )
  result.0.state
  |> should.equal(opencode_session.Error("connection failed"))
}

pub fn view_loading_shows_loading_text_test() {
  let model = test_model()
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "Loading opencode...") |> should.be_true
}

pub fn view_ready_contains_iframe_test() {
  let model =
    campaigner_app.Model(
      opencode_session.Ready("http://example.com/iframe"),
      test_vault_encoded(),
    )
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "iframe") |> should.be_true
}

pub fn view_error_shows_error_message_test() {
  let model =
    campaigner_app.Model(opencode_session.Error("oops"), test_vault_encoded())
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "Error: oops") |> should.be_true
}

pub fn view_always_has_left_pane_test() {
  let model = test_model()
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "Left Pane") |> should.be_true
}

pub fn test_vault_encoded_matches_vault_path_base64_test() {
  let actual_path = obsidian_vault.vault_path()
  let expected_encoded =
    "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0Lw=="
  actual_path |> should.equal(test_vault_path())
  test_vault_encoded() |> should.equal(expected_encoded)
}
