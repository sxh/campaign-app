import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute

pub type DashboardViewModel {
  DashboardViewModel(
    vault_path: String,
    total_files: String,
    md_files: String,
    total_characters: String,
    image_files: String,
    notes_message: String,
    chars_message: String
  )
}

pub type ErrorViewModel {
  ErrorViewModel(
    title: String,
    message: String
  )
}

pub fn layout(title: String, content: Element(msg)) -> Element(msg) {
  html.html([], [
    html.head([], [
      html.title([], title),
      html.meta([
        attribute.attribute("charset", "utf-8")
      ]),
      html.meta([
        attribute.attribute("name", "viewport"),
        attribute.attribute("content", "width=device-width, initial-scale=1")
      ]),
      html.style([], "
        body {
          font-family: sans-serif;
          line-height: 1.5;
          color: #333;
          max-width: 800px;
          margin: 0 auto;
          padding: 2rem;
          background-color: #f4f4f9;
        }
        h1 { color: #2c3e50; }
        code {
          background-color: #eee;
          padding: 0.2rem 0.4rem;
          border-radius: 3px;
        }
        ul { list-style-type: none; padding: 0; }
        li { margin-bottom: 0.5rem; padding: 0.5rem; background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        footer { margin-top: 2rem; font-size: 0.8rem; color: #777; border-top: 1px solid #ddd; padding-top: 1rem; }
        .error { color: #e74c3c; }
        a { color: #3498db; text-decoration: none; }
        a:hover { text-decoration: underline; }
      ")
    ]),
    html.body([], [
      content
    ])
  ])
}

pub fn render_dashboard(vm: DashboardViewModel) {
  html.div([], [
    html.h1([], [element.text("Campaigner Dashboard")]),
    html.p([], [element.text("Hello World from Lustre!")]),
    html.h2([], [element.text("Obsidian Vault Stats")]),
    html.ul([], [
      html.li([], [
        element.text("Vault Path: "),
        html.code([], [element.text(vm.vault_path)])
      ]),
      html.li([], [
        element.text("Total Files: "),
        element.text(vm.total_files)
      ]),
      html.li([], [
        element.text("Markdown Notes: "),
        element.text(vm.md_files)
      ]),
      html.li([], [
        element.text("Total Characters in Notes: "),
        element.text(vm.total_characters)
      ]),
      html.li([], [
        element.text("Images: "),
        element.text(vm.image_files)
      ])
    ]),
    html.p([], [element.text(vm.notes_message)]),
    html.p([], [element.text(vm.chars_message)]),
    html.footer([], [
      element.text("Built with Gleam, Lustre, and Mist.")
    ])
  ])
}

pub fn render_error_page(vm: ErrorViewModel) -> Element(msg) {
  html.div([attribute.class("error")], [
    html.h1([], [element.text(vm.title)]),
    html.p([], [element.text(vm.message)]),
    html.a([attribute.attribute("href", "/")], [element.text("Back to Dashboard")])
  ])
}

pub fn render_404() -> Element(msg) {
  html.div([], [
    html.h1([], [element.text("404 - Not Found")]),
    html.p([], [element.text("The page you are looking for does not exist.")]),
    html.a([attribute.attribute("href", "/")], [element.text("Back to Dashboard")])
  ])
}
