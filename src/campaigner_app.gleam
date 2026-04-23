import electron_preload
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import opencode_session.{type OpenCodeState, Error, Loading, Ready}

pub type Model {
  Model(state: OpenCodeState)
}

pub type Msg {
  SessionReady(slug: String)
  SessionError(error: String)
}

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let create_url = opencode_session.session_create_url()

  let effect =
    effect.from(fn(dispatch) {
      electron_preload.create_session_and_dispatch(
        create_url,
        fn(slug) { dispatch(SessionReady(slug)) },
        fn(msg) { dispatch(SessionError(msg)) },
      )
    })

  #(Model(Loading), effect)
}

pub fn update(_model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SessionReady(slug) -> {
      let url = opencode_session.session_iframe_url(slug)
      #(Model(Ready(url)), effect.none())
    }
    SessionError(e) -> #(Model(Error(e)), effect.none())
  }
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
      left_pane(),
      right_pane(model.state),
    ],
  )
}

fn left_pane() -> Element(Msg) {
  html.div(
    [
      attribute.styles([
        #("flex", "1"),
        #("padding", "16px"),
        #("border-right", "1px solid #ccc"),
      ]),
    ],
    [
      html.h1([], [html.text("Left Pane")]),
      html.p([], [html.text("Placeholder")]),
    ],
  )
}

fn right_pane(state: OpenCodeState) -> Element(Msg) {
  html.div(
    [attribute.styles([#("flex", "1"), #("padding", "16px")])],
    case state {
      Loading -> [html.h1([], [html.text("Loading opencode...")])]
      Ready(url) -> [
        html.iframe([
          attribute.src(url),
          attribute.attribute("allow", "clipboard-read; clipboard-write"),
          attribute.styles([
            #("width", "100%"),
            #("height", "100%"),
            #("border", "none"),
          ]),
        ]),
      ]
      Error(msg) -> [html.h1([], [html.text("Error: " <> msg)])]
    },
  )
}
