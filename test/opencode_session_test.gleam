import gleeunit
import gleeunit/should
import opencode_session

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn session_create_url_returns_correct_endpoint_test() {
  let result = opencode_session.session_create_url()
  result |> should.equal("http://127.0.0.1:14096/session")
}

pub fn session_iframe_url_includes_encoded_path_and_session_id_test() {
  let encoded = "dGVzdC1lbmNvZGVkLXBhdGg="
  let result = opencode_session.session_iframe_url(encoded, "ses_abc123")
  result
  |> should.equal(
    "http://127.0.0.1:14096/dGVzdC1lbmNvZGVkLXBhdGg=/session/ses_abc123",
  )
}
