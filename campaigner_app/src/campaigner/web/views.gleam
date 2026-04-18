import gleam/int
import campaigner/vault.{type Stats}
import lustre/element
import lustre/element/html

pub fn render_dashboard(stats: Stats) {
  let notes_msg = get_notes_message(stats.md_files)
  let char_msg = get_chars_message(stats.total_characters)

  html.div([], [
    html.h1([], [element.text("Campaigner Dashboard")]),
    html.p([], [element.text("Hello World from Lustre!")]),
    html.h2([], [element.text("Obsidian Vault Stats")]),
    html.ul([], [
      html.li([], [
        element.text("Vault Path: "),
        html.code([], [element.text(stats.vault_path)])
      ]),
      html.li([], [
        element.text("Total Files: "),
        element.text(int.to_string(stats.total_files))
      ]),
      html.li([], [
        element.text("Markdown Notes: "),
        element.text(int.to_string(stats.md_files))
      ]),
      html.li([], [
        element.text("Total Characters in Notes: "),
        element.text(int.to_string(stats.total_characters))
      ]),
      html.li([], [
        element.text("Images: "),
        element.text(int.to_string(stats.image_files))
      ])
    ]),
    html.p([], [element.text(notes_msg)]),
    html.p([], [element.text(char_msg)]),
    html.footer([], [
      element.text("Built with Gleam, Lustre, and Mist.")
    ])
  ])
}

pub fn get_notes_message(count: Int) -> String {
  case count > 0 {
    True -> "You have some notes!"
    False -> "No notes found."
  }
}

pub fn get_chars_message(count: Int) -> String {
  case count > 1000 {
    True -> "Wow, that's a lot of writing!"
    False -> "Keep writing!"
  }
}
