import campaigner/services/dashboard_service as service
import campaigner/vault
import campaigner/web/views
import gleam/bytes_tree.{type BytesTree}
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
import gleam/string
import lustre/element

pub type Route {
  Dashboard
  Chat
  NotFound
}

pub fn parse_route(path: List(String)) -> Route {
  case path {
    [] -> Dashboard
    ["chat"] -> Chat
    _ -> NotFound
  }
}

pub fn router(
  req: Request(t),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Response(BytesTree) {
  case parse_route(request.path_segments(req)) {
    Dashboard -> serve_dashboard(vault_path, ctx)
    Chat -> serve_chat(req, vault_path, ctx)
    NotFound -> serve_404()
  }
}

pub fn serve_dashboard(
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Response(BytesTree) {
  case service.prepare_dashboard_data(vault_path, ctx) {
    Ok(data) -> {
      service.render_dashboard_page(data)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(200), _)
    }
    Error(err) -> {
      service.render_error_page(err)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(500), _)
    }
  }
}

pub fn serve_chat(
  req: Request(t),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Response(BytesTree) {
  case req.method {
    Get -> {
      let vm = views.ChatViewModel(prompt: "", response: "", error: "")
      service.render_chat_page(vm)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(200), _)
    }
    Post -> {
      // Very basic form parsing for now
      // In a real app we'd use a proper form decoder
      let query = request.get_query(req) |> result.unwrap([])
      let prompt =
        list.key_find(query, "prompt") |> result.unwrap("") |> string.trim

      case prompt {
        "" -> {
          let vm =
            views.ChatViewModel(
              prompt: "",
              response: "",
              error: "Please enter a question.",
            )
          service.render_chat_page(vm)
          |> element.to_string
          |> bytes_tree.from_string
          |> response.set_body(response.new(200), _)
        }
        _ -> {
          case service.ask_vault(prompt, vault_path, ctx) {
            Ok(res) -> {
              let vm =
                views.ChatViewModel(prompt: prompt, response: res, error: "")
              service.render_chat_page(vm)
              |> element.to_string
              |> bytes_tree.from_string
              |> response.set_body(response.new(200), _)
            }
            Error(err) -> {
              let vm =
                views.ChatViewModel(prompt: prompt, response: "", error: err)
              service.render_chat_page(vm)
              |> element.to_string
              |> bytes_tree.from_string
              |> response.set_body(response.new(200), _)
            }
          }
        }
      }
    }
    _ -> serve_404()
  }
}

pub fn serve_404() -> Response(BytesTree) {
  service.render_404_page()
  |> element.to_string
  |> bytes_tree.from_string
  |> response.set_body(response.new(404), _)
}
