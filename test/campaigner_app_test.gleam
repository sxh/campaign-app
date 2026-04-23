import campaigner_app
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import opencode_session

pub fn main() -> Nil {
  gleeunit.main()
}

fn test_model() -> campaigner_app.Model {
  campaigner_app.Model(opencode_session.Loading)
}

pub fn init_returns_loading_model_test() {
  let #(model, _eff) = campaigner_app.init(Nil)
  model.state |> should.equal(opencode_session.Loading)
}

pub fn update_session_ready_transitions_to_ready_test() {
  let model = test_model()
  let result =
    campaigner_app.update(model, campaigner_app.SessionReady("sunny-planet"))
  let expected_url = opencode_session.session_iframe_url("sunny-planet")
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
    campaigner_app.Model(opencode_session.Ready("http://example.com/iframe"))
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "iframe") |> should.be_true
}

pub fn view_error_shows_error_message_test() {
  let model = campaigner_app.Model(opencode_session.Error("oops"))
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
