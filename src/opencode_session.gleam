pub type OpenCodeState {
  Loading
  Ready(url: String)
  Error(message: String)
}

pub fn session_create_url() -> String {
  "http://127.0.0.1:14096/session"
}

pub fn session_iframe_url(slug: String) -> String {
  "http://127.0.0.1:14096/s/" <> slug
}

pub fn session_data_url(session_id: String) -> String {
  "http://127.0.0.1:14096/session/" <> session_id
}
