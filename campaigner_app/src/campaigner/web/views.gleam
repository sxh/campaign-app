import campaigner/web/assets
import lustre/attribute.{class, href, method, name, placeholder, type_}
import lustre/element.{type Element}
import lustre/element/html.{
  a, body, button, div, form, h1, h2, head, html, main, p, script, section, span,
  text, textarea,
}

pub type DashboardViewModel {
  DashboardViewModel(
    vault_path: String,
    total_files: String,
    md_files: String,
    total_characters: String,
    image_files: String,
    notes_message: String,
    chars_message: String,
  )
}

pub type ErrorViewModel {
  ErrorViewModel(title: String, message: String)
}

pub type ChatViewModel {
  ChatViewModel(
    vault_path: String,
    prompt: String,
    response: String,
    error: String,
  )
}

pub fn layout(title: String, content: Element(msg)) -> Element(msg) {
  html([], [
    head([], [
      html.title([], title),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.style([], assets.css()),
    ]),
    body([], [
      html.nav([class("navbar")], [
        div([class("container")], [
          a([href("/"), class("nav-brand")], [text("Campaigner")]),
          div([class("nav-links")], [
            a([href("/"), class("nav-link")], [text("Dashboard")]),
            a([href("/chat"), class("nav-link")], [text("Chat")]),
          ]),
        ]),
      ]),
      main([class("container")], [content]),
    ]),
  ])
}

pub fn render_dashboard(vm: DashboardViewModel) -> Element(msg) {
  section([class("dashboard")], [
    h1([], [text("Campaigner Dashboard")]),
    p([class("vault-path")], [
      text("Vault Path: "),
      html.code([], [text(vm.vault_path)]),
    ]),
    div([class("stats-grid")], [
      div([class("stat-card")], [
        h2([], [text("Total Files")]),
        p([class("stat-value")], [text(vm.total_files)]),
      ]),
      div([class("stat-card")], [
        h2([], [text("Markdown Notes")]),
        p([class("stat-value")], [text(vm.md_files)]),
        p([class("stat-message")], [text(vm.notes_message)]),
      ]),
      div([class("stat-card")], [
        h2([], [text("Images")]),
        p([class("stat-value")], [text(vm.image_files)]),
      ]),
      div([class("stat-card")], [
        h2([], [text("Character Count")]),
        p([class("stat-value")], [text(vm.total_characters)]),
        p([class("stat-message")], [text(vm.chars_message)]),
      ]),
    ]),
    div([class("actions")], [
      a([href("/chat"), class("btn-primary")], [text("Chat with your Vault")]),
    ]),
  ])
}

pub fn render_chat(vm: ChatViewModel) -> Element(msg) {
  section([class("chat-container")], [
    h1([], [text("Chat with your Vault")]),
    p([], [
      text(
        "Ask questions about your campaign notes using the power of Gemini CLI.",
      ),
    ]),
    // Terminal emulator section
    div([class("terminal-container")], [
      div([class("terminal-header")], [
        span([class("terminal-title")], [text("Vault Terminal")]),
        span([class("terminal-path")], [
          text("Path: "),
          html.code([], [text(vm.vault_path)]),
        ]),
      ]),
      div([class("terminal-body")], [
        div([class("terminal-line")], [
          span([class("terminal-prompt")], [text("$ ")]),
          span([class("terminal-command")], [
            text("cd "),
            html.code([], [text(vm.vault_path)]),
          ]),
        ]),
        div([class("terminal-line")], [
          span([class("terminal-prompt")], [text("$ ")]),
          span([class("terminal-command")], [text("ls -la | head -5")]),
        ]),
        div([class("terminal-line")], [
          span([class("terminal-output")], [
            text("(Terminal opened in vault folder)"),
          ]),
        ]),
        div([class("terminal-line")], [
          span([class("terminal-output")], [
            text(
              "Use the chat below to ask questions about your vault contents.",
            ),
          ]),
        ]),
      ]),
    ]),
    form([method("POST"), class("chat-form")], [
      div([class("form-group")], [
        textarea(
          [
            name("prompt"),
            placeholder("How many villages are in the Sword Coast?"),
            class("chat-input"),
          ],
          vm.prompt,
        ),
      ]),
      div([class("form-actions")], [
        button([type_("submit"), class("btn-submit")], [
          span([class("spinner")], []),
          span([class("btn-text")], [text("Ask Gemini")]),
        ]),
      ]),
    ]),
    script(
      [],
      "document.querySelector('.chat-form').addEventListener('submit', function() { const form = this; if (form.dataset.submitting) return; form.dataset.submitting = 'true'; this.querySelector('.btn-submit').classList.add('loading'); this.querySelector('.chat-input').setAttribute('readonly', 'readonly'); });",
    ),
    case vm.error {
      "" -> element.none()
      err -> div([class("alert-error")], [text(err)])
    },
    case vm.response {
      "" -> element.none()
      res ->
        div([class("chat-response")], [
          h2([], [text("Gemini Response")]),
          div([class("response-content")], [text(res)]),
        ])
    },
  ])
}

pub fn render_error_page(vm: ErrorViewModel) -> Element(msg) {
  section([class("error-page")], [
    h1([], [text(vm.title)]),
    p([], [text(vm.message)]),
    a([href("/")], [text("Return to Dashboard")]),
  ])
}

pub fn render_404() -> Element(msg) {
  section([class("error-page")], [
    h1([], [text("404 - Not Found")]),
    p([], [text("The page you are looking for does not exist.")]),
    a([href("/")], [text("Return to Dashboard")]),
  ])
}
