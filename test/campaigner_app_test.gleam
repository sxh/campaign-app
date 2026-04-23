import campaigner_app
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn app_model_has_initial_count_of_zero_test() {
  let model = campaigner_app.initial_model(Nil)
  model.count |> should.equal(0)
}

pub fn view_model_contains_hello_world_test() {
  let model = campaigner_app.initial_model(Nil)
  let display = campaigner_app.view_text(model)
  display |> should.equal("Hello, World! Count: 0")
}

pub fn increment_message_is_increment_test() {
  campaigner_app.Increment |> should.equal(campaigner_app.Increment)
}

pub fn update_with_increment_increases_count_test() {
  let model = campaigner_app.initial_model(Nil)
  let result = campaigner_app.update(model, campaigner_app.Increment)
  result.count |> should.equal(1)
}

pub fn view_returns_html_with_hello_world_test() {
  let model = campaigner_app.initial_model(Nil)
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "Hello, World!") |> should.be_true
}

pub fn view_returns_html_with_button_test() {
  let model = campaigner_app.initial_model(Nil)
  let view = campaigner_app.view(model)
  let html = element.to_string(view)
  string.contains(html, "button") |> should.be_true
}
