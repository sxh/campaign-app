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

pub fn session_iframe_url_includes_slug_test() {
  let result = opencode_session.session_iframe_url("sunny-planet")
  result |> should.equal("http://127.0.0.1:14096/s/sunny-planet")
}

pub fn session_data_url_includes_session_id_test() {
  let result = opencode_session.session_data_url("ses_abc123")
  result |> should.equal("http://127.0.0.1:14096/session/ses_abc123")
}
