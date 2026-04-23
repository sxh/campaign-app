import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub type Model {
  Model(opencode_iframe_url: String)
}

pub type Msg {
  NoOp
}

pub type InitFlags {
  InitFlags(opencode_iframe_url: String)
}

pub fn init(flags: InitFlags) -> #(Model, Effect(Msg)) {
  #(Model(flags.opencode_iframe_url), effect.none())
}

pub fn update(model: Model, _msg: Msg) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

pub fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("width", "100%"),
        #("height", "100vh"),
      ]),
    ],
    [
      vault_pane(),
      opencode_pane(model.opencode_iframe_url),
    ],
  )
}

fn vault_pane() -> Element(Msg) {
  html.div(
    [
      attribute.styles([
        #("flex", "1"),
        #("padding", "16px"),
        #("border-right", "1px solid #ccc"),
      ]),
    ],
    [
      html.h1([], [html.text("Vault")]),
      html.p([], [html.text("Vault management")]),
    ],
  )
}

fn opencode_pane(url: String) -> Element(Msg) {
  html.div([attribute.styles([#("flex", "1"), #("padding", "16px")])], [
    html.iframe([
      attribute.src(url),
      attribute.attribute("allow", "clipboard-read; clipboard-write"),
      attribute.styles([
        #("width", "100%"),
        #("height", "100%"),
        #("border", "none"),
      ]),
    ]),
  ])
}
