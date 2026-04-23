import campaigner/config
import campaigner/services/dashboard_service as service
import campaigner/vault
import campaigner/web/views
import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
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
  req: Request(BitArray),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Response(BytesTree) {
  let default_config = config.from_vault_path(vault_path)
  router_with_config(req, vault_path, ctx, default_config)
}

pub fn router_with_config(
  req: Request(BitArray),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
  config: config.Config,
) -> Response(BytesTree) {
  case parse_route(request.path_segments(req)) {
    Dashboard -> serve_dashboard(vault_path, ctx, config)
    Chat -> serve_chat(req, vault_path, ctx)
    NotFound -> serve_404()
  }
}

pub fn serve_dashboard(
  vault_path: vault.VaultPath,
  ctx: vault.Context,
  config: config.Config,
) -> Response(BytesTree) {
  case service.prepare_dashboard_with_sidebar(vault_path, ctx, config) {
    Ok(data) -> {
      service.render_sidebar_page(data)
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
  req: Request(BitArray),
  vault_path: vault.VaultPath,
  ctx: vault.Context,
) -> Response(BytesTree) {
  let vault_path_str = vault.vault_path_to_string(vault_path)

  case req.method {
    Get -> {
      let vm =
        views.ChatViewModel(
          vault_path: vault_path_str,
          prompt: "",
          response: "",
          error: "",
        )
      service.render_chat_page(vm)
      |> element.to_string
      |> bytes_tree.from_string
      |> response.set_body(response.new(200), _)
    }
    Post -> {
      let body_string = bit_array.to_string(req.body) |> result.unwrap("")
      ctx.logger.info("POST /chat body: " <> body_string, [])

      let query = uri.parse_query(body_string) |> result.unwrap([])
      let prompt =
        list.key_find(query, "prompt") |> result.unwrap("") |> string.trim
      ctx.logger.info("Parsed prompt: '" <> prompt <> "'", [])

      case prompt {
        "" -> {
          let vm =
            views.ChatViewModel(
              vault_path: vault_path_str,
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
                views.ChatViewModel(
                  vault_path: vault_path_str,
                  prompt: prompt,
                  response: res,
                  error: "",
                )
              service.render_chat_page(vm)
              |> element.to_string
              |> bytes_tree.from_string
              |> response.set_body(response.new(200), _)
            }
            Error(err) -> {
              let vm =
                views.ChatViewModel(
                  vault_path: vault_path_str,
                  prompt: prompt,
                  response: "",
                  error: err,
                )
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
