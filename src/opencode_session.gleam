pub type OpenCodeState {
  Loading
  Ready(url: String)
  Error(message: String)
}

pub fn session_create_url() -> String {
  "http://127.0.0.1:14096/session"
}

pub fn session_iframe_url(encoded_path: String, session_id: String) -> String {
  "http://127.0.0.1:14096/" <> encoded_path <> "/session/" <> session_id
}
