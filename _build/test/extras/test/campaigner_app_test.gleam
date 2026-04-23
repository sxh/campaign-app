import campaigner_app
import gleeunit
import gleeunit/should

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
