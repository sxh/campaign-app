import gleeunit
import gleeunit/should
import opencode_session

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn session_iframe_url_includes_encoded_vault_path_test() {
  let encoded = "L3VzZXJzL3Rlc3QvdmF1bHQ"
  let result = opencode_session.session_iframe_url(encoded)
  result
  |> should.equal("http://127.0.0.1:14096/L3VzZXJzL3Rlc3QvdmF1bHQ/session")
}

pub fn session_iframe_url_uses_correct_vault_encoding_test() {
  let encoded =
    "L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0"
  let result = opencode_session.session_iframe_url(encoded)
  result
  |> should.equal(
    "http://127.0.0.1:14096/L1VzZXJzL3N0ZXZlLmhheWVzL0xpYnJhcnkvTW9iaWxlIERvY3VtZW50cy9pQ2xvdWR+bWR+b2JzaWRpYW4vRG9jdW1lbnRzL0ZvcmdvdHRlblJlYWxtc1ZhdWx0/session",
  )
}
