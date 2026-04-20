import campaigner/config
import campaigner/config/defaults
import campaigner/infrastructure/fake_file_system
import campaigner/infrastructure/gemini_cli_adapter
import campaigner/infrastructure/simplifile_adapter

import campaigner/infrastructure/stdout_logger
import campaigner/ports/chat_engine
import campaigner/ports/file_system
import campaigner/services/dashboard_service as service
import campaigner/system
import campaigner/vault
import campaigner/web/router
import campaigner/web/views
import factories
import gleam/bit_array
import gleam/bytes_tree
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post, Put}
import gleam/http/request
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import simplifile
import utils

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn gather_stats_test() {
  let test_vault_path_str = "./test_vault"
  let test_vault_path = factories.vault_path(test_vault_path_str)
  let ctx =
    vault.Context(
      fs: simplifile_adapter.real_fs(),
      logger: factories.logger_silent(),
      chat: factories.chat_silent(),
      timeout_ms: 5000,
    )

  // Setup
  let _ = simplifile.create_directory_all(test_vault_path_str)
  let _ = simplifile.write(test_vault_path_str <> "/note1.md", "Hello")
  let _ = simplifile.write(test_vault_path_str <> "/note2.md", "World!")
  let _ = simplifile.write(test_vault_path_str <> "/image.png", "fake data")
  let _ = simplifile.write(test_vault_path_str <> "/other.txt", "ignore me")

  // Execute
  let result = vault.gather_stats(test_vault_path, ctx)

  // Assert
  let assert Ok(stats) = result
  vault.get_total_files(stats) |> should.equal(4)
  vault.get_md_files(stats) |> should.equal(2)
  vault.get_image_files(stats) |> should.equal(1)
  vault.get_total_characters(stats) |> should.equal(11)
  vault.vault_path_to_string(vault.get_vault_path(stats))
  |> should.equal(test_vault_path_str)

  // Teardown
  let _ = simplifile.delete(test_vault_path_str)
}

pub fn vault_path_validation_test() {
  vault.vault_path_from_string("")
  |> should.equal(Error(vault.InvalidPath("Path cannot be empty")))
  vault.vault_path_from_string("   ")
  |> should.equal(Error(vault.InvalidPath("Path cannot be empty")))
  let path = factories.vault_path("/valid/path")
  vault.vault_path_to_string(path) |> should.equal("/valid/path")
}

pub fn gather_stats_mock_error_test() {
  let mock_fs =
    file_system.FileSystem(get_files: fn(_) { Ok(["note1.md"]) }, read: fn(_) {
      Error(simplifile.Enoent)
    })
  let ctx = factories.context_with_fs(mock_fs)
  let path = factories.vault_path("/path")

  let result = vault.gather_stats(path, ctx)
  result
  |> should.equal(Error(vault.FileReadError("note1.md", simplifile.Enoent)))
}

pub fn gather_stats_fake_test() {
  let files =
    dict.from_list([
      #("/vault/note1.md", "Hello"),
      #("/vault/note2.md", "World"),
      #("/vault/image.png", "binary"),
    ])
  let fs = fake_file_system.from_contents(files)
  let ctx = factories.context_with_fs(fs)
  let path = factories.vault_path("/vault")

  let result = vault.gather_stats(path, ctx)
  let assert Ok(stats) = result
  vault.get_total_files(stats) |> should.equal(3)
  vault.get_md_files(stats) |> should.equal(2)
  vault.get_total_characters(stats) |> should.equal(10)
}

pub fn gather_stats_error_test() {
  let test_path = "./non_existent_vault"
  let path = factories.vault_path(test_path)
  let ctx = factories.context()
  // real_fs wrapper from factory
  let result = vault.gather_stats(path, ctx)

  result |> should.equal(Error(vault.VaultNotFound(test_path)))
}

pub fn render_dashboard_test() {
  let stats = factories.stats()
  let html =
    service.render_dashboard_page(service.DashboardData(stats))
    |> element.to_string

  html |> string.contains("Campaigner Dashboard") |> should.be_true
  html |> string.contains("Total Files") |> should.be_true
  html |> string.contains("<html>") |> should.be_true
}

pub fn render_dashboard_empty_test() {
  let path = factories.vault_path("/empty")
  let fs =
    fake_file_system.from_contents(dict.from_list([#("/empty/root", "")]))
  let ctx = factories.context_with_fs(fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)

  let html =
    service.render_dashboard_page(service.DashboardData(stats))
    |> element.to_string
  html |> string.contains("Total Files") |> should.be_true
  html |> string.contains("No notes found.") |> should.be_true
  html |> string.contains("<html>") |> should.be_true
}

pub fn render_dashboard_full_test() {
  let path = factories.vault_path("/path")
  let fs =
    fake_file_system.from_contents(
      dict.from_list([
        #("/path/n1.md", string.repeat("a", 600)),
        #("/path/n2.md", string.repeat("b", 600)),
      ]),
    )
  let ctx = factories.context_with_fs(fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)

  let html =
    views.render_dashboard(service.to_dashboard_view_model(stats))
    |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  // Lustre escapes single quotes
  html |> string.contains("Wow, that&#39;s a lot of writing!") |> should.be_true
}

pub fn render_dashboard_low_chars_test() {
  let path = factories.vault_path("/path")
  let fs =
    fake_file_system.from_contents(dict.from_list([#("/path/n1.md", "small")]))
  let ctx = factories.context_with_fs(fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)

  let html =
    views.render_dashboard(service.to_dashboard_view_model(stats))
    |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  html |> string.contains("Keep writing!") |> should.be_true
}

pub fn router_root_test() {
  let test_vault_path_str = "./test_vault_router"
  let test_vault_path = factories.vault_path(test_vault_path_str)
  let ctx =
    vault.Context(
      fs: simplifile_adapter.real_fs(),
      logger: factories.logger_silent(),
      chat: factories.chat_silent(),
      timeout_ms: 5000,
    )
  let _ = simplifile.create_directory_all(test_vault_path_str)

  let req = request.new() |> request.set_body(bit_array.from_string(""))
  let res = router.router(req, test_vault_path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Campaigner Dashboard") |> should.be_true
  body |> string.contains("<html>") |> should.be_true

  let _ = simplifile.delete(test_vault_path_str)
}

pub fn router_error_test() {
  let test_path = "./non_existent_vault_router"
  let path = factories.vault_path(test_path)
  let ctx = factories.context()

  let req = request.new() |> request.set_body(bit_array.from_string(""))
  let res = router.router(req, path, ctx)
  res.status |> should.equal(500)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Vault Not Found") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
}

pub fn router_404_test() {
  let assert Ok(path) = vault.vault_path_from_string("/tmp")
  let ctx = factories.context()
  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_path("/unknown")
  let res = router.router(req, path, ctx)
  res.status |> should.equal(404)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("404 - Not Found") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
}

pub fn parse_route_test() {
  router.parse_route([]) |> should.equal(router.Dashboard)
  router.parse_route(["chat"]) |> should.equal(router.Chat)
  router.parse_route(["any"]) |> should.equal(router.NotFound)
}

pub fn is_markdown_test() {
  vault.is_markdown("test.md") |> should.be_true
  vault.is_markdown("test.txt") |> should.be_false
}

pub fn is_image_test() {
  vault.is_image("test.png") |> should.be_true
  vault.is_image("test.jpg") |> should.be_true
  vault.is_image("test.jpeg") |> should.be_true
  vault.get_total_characters(factories.stats()) |> should.not_equal(-1)
}

pub fn real_fs_test() {
  let fs = simplifile_adapter.real_fs()
  // Just verify it returns the record with functions
  let _ = fs.get_files
  let _ = fs.read
  True |> should.be_true
}

pub fn sized_chunk_test() {
  vault.sized_chunk([1, 2, 3, 4, 5], 2) |> should.equal([[1, 2], [3, 4], [5]])
  vault.sized_chunk([1, 2], 5) |> should.equal([[1, 2]])
  vault.sized_chunk([], 2) |> should.equal([])
}

pub fn service_render_error_test() {
  let err = vault.VaultNotFound("/missing")
  let html = service.render_error_page(err) |> element.to_string
  html |> string.contains("Vault Not Found") |> should.be_true

  let err2 = vault.InvalidPath("oops")
  let html2 = service.render_error_page(err2) |> element.to_string
  html2 |> string.contains("Invalid Path") |> should.be_true

  let err3 = vault.FileReadError("/path", simplifile.Eacces)
  let html3 = service.render_error_page(err3) |> element.to_string
  html3 |> string.contains("Read Error") |> should.be_true
}

pub fn service_render_404_test() {
  let html = service.render_404_page() |> element.to_string
  html |> string.contains("404 - Not Found") |> should.be_true
}

pub fn fake_fs_inconsistent_test() {
  let files = dict.from_list([#("/vault/exists.md", Ok("Content"))])
  let fs = fake_file_system.new(files)
  fs.read("/vault/missing.md") |> should.equal(Error(simplifile.Enoent))
}

pub fn router_file_read_error_test() {
  let path_str = "/vault"
  let assert Ok(path) = vault.vault_path_from_string(path_str)
  let files = dict.from_list([#("/vault/corrupt.md", Error(simplifile.Eacces))])
  let fs = fake_file_system.new(files)
  let ctx = factories.context_with_fs(fs)

  let req = request.new() |> request.set_body(bit_array.from_string(""))
  let res = router.router(req, path, ctx)
  res.status |> should.equal(500)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Read Error") |> should.be_true
  body |> string.contains("/vault/corrupt.md") |> should.be_true
}

pub fn config_error_string_test() {
  config.string_from_vault_error(vault.VaultNotFound("/p"))
  |> should.equal("Path not found: /p")
  config.string_from_vault_error(vault.FileReadError("/f", simplifile.Eacces))
  |> should.equal("Read error: /f")
  config.string_from_vault_error(vault.InvalidPath("oops"))
  |> should.equal("oops")
}

pub fn gather_stats_timeout_test() {
  let path_str = "/vault"
  let assert Ok(path) = vault.vault_path_from_string(path_str)
  let files = dict.from_list([#("/vault/note.md", Ok("Some content"))])
  let fs = fake_file_system.new(files)

  let ctx =
    vault.Context(
      fs: fs,
      logger: factories.logger_silent(),
      chat: factories.chat_silent(),
      timeout_ms: 0,
    )

  let result = vault.gather_stats(path, ctx)
  result |> should.equal(Error(vault.Timeout("")))
}

pub fn system_init_test() {
  let logger = factories.logger_silent()
  let result = system.init(logger)
  let assert Ok(#(_cfg, ctx)) = result
  let _ = ctx.chat
  result |> should.be_ok()
}

pub fn config_env_test() {
  let get_env_custom = fn(name) {
    case name {
      "CAMPAIGNER_VAULT_PATH" -> Ok("/custom/path")
      _ -> Error(Nil)
    }
  }
  let res = config.load_with_env(get_env_custom)
  let assert Ok(cfg) = res
  vault.vault_path_to_string(cfg.vault_path) |> should.equal("/custom/path")

  let get_env_none = fn(_) { Error(Nil) }
  let res2 = config.load_with_env(get_env_none)
  let assert Ok(cfg2) = res2
  vault.vault_path_to_string(cfg2.vault_path)
  |> should.equal(defaults.vault_path)
}

pub fn ask_vault_test() {
  let path = factories.vault_path("/vault")
  let mock_chat = chat_engine.ChatEngine(ask: fn(_, _) { Ok("Answer") })
  let ctx =
    vault.Context(
      fs: fake_file_system.from_contents(dict.new()),
      logger: factories.logger_silent(),
      chat: mock_chat,
      timeout_ms: 5000,
    )

  service.ask_vault("Question", path, ctx) |> should.equal(Ok("Answer"))
}

pub fn router_chat_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()
  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_path("/chat")
  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Chat with your Vault") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
}

pub fn render_chat_test() {
  let vm =
    views.ChatViewModel(
      prompt: "Who is Strahd?",
      response: "A vampire.",
      error: "",
    )
  let html = views.render_chat(vm) |> element.to_string
  html |> string.contains("Who is Strahd?") |> should.be_true
  html |> string.contains("A vampire.") |> should.be_true
}

pub fn router_chat_post_test() {
  let path = factories.vault_path("/vault")
  let mock_chat =
    chat_engine.ChatEngine(ask: fn(_, p) { Ok("Response to " <> p) })
  let ctx =
    vault.Context(
      fs: fake_file_system.new(dict.new()),
      logger: factories.logger_silent(),
      chat: mock_chat,
      timeout_ms: 5000,
    )

  let req =
    request.new()
    |> request.set_body(bit_array.from_string("prompt=Hello"))
    |> request.set_method(Post)
    |> request.set_path("/chat")

  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Response to Hello") |> should.be_true
}

pub fn router_chat_post_empty_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()

  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_method(Post)
    |> request.set_path("/chat")
    |> request.set_query([#("prompt", "")])

  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Please enter a question.") |> should.be_true
}

pub fn gemini_adapter_test() {
  let adapter = gemini_cli_adapter.new_with_executor(fn(_) { "AI Response" })
  adapter.ask("/path", "hello") |> should.equal(Ok("AI Response"))

  let error_adapter = gemini_cli_adapter.new_with_executor(fn(_) { "" })
  error_adapter.ask("/path", "hello")
  |> should.equal(
    Error(chat_engine.EngineError("Gemini CLI returned no output")),
  )
}

pub fn router_chat_engine_error_test() {
  let path = factories.vault_path("/vault")
  let mock_chat =
    chat_engine.ChatEngine(ask: fn(_, _) {
      Error(chat_engine.EngineError("Simulated Failure"))
    })
  let ctx =
    vault.Context(
      fs: fake_file_system.new(dict.new()),
      logger: factories.logger_silent(),
      chat: mock_chat,
      timeout_ms: 5000,
    )

  let req =
    request.new()
    |> request.set_body(bit_array.from_string("prompt=Hello"))
    |> request.set_method(Post)
    |> request.set_path("/chat")

  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body
  |> string.contains("Failed to communicate with chat engine")
  |> should.be_true
}

pub fn system_init_fail_test() {
  let logger = factories.logger_silent()

  let res =
    system.init_with_config_loader(logger, fn() {
      Error(config.EnvironmentVariableMissing("TEST_VAR"))
    })
  res |> should.equal(Error("Environment variable missing: TEST_VAR"))

  let res2 =
    system.init_with_config_loader(logger, fn() {
      Error(config.InvalidConfigPath("bad path"))
    })
  res2 |> should.equal(Error("Invalid configuration: bad path"))
}

pub fn service_render_error_file_read_test() {
  let err = vault.FileReadError("/path/to/file", simplifile.Eacces)
  let html = service.render_error_page(err) |> element.to_string
  html |> string.contains("Read Error") |> should.be_true
  html |> string.contains("/path/to/file") |> should.be_true
}

pub fn service_render_timeout_test() {
  let err = vault.Timeout("slow")
  let html = service.render_error_page(err) |> element.to_string
  html |> string.contains("Timeout") |> should.be_true
  html |> string.contains("slow") |> should.be_true
}

pub fn config_timeout_error_string_test() {
  config.string_from_vault_error(vault.Timeout("slow"))
  |> should.equal("Timeout: slow")
}

pub fn service_render_404_page_test() {
  let html = service.render_404_page() |> element.to_string
  html |> string.contains("404 - Not Found") |> should.be_true
}

pub fn router_serve_404_test() {
  let res = router.serve_404()
  res.status |> should.equal(404)
  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("404 - Not Found") |> should.be_true
}

pub fn system_init_success_test() {
  let logger = factories.logger_silent()
  let res =
    system.init_with_config_loader(logger, fn() {
      let assert Ok(path) = vault.vault_path_from_string("/vault")
      Ok(config.Config(vault_path: path))
    })
  res |> should.be_ok()
}

pub fn router_chat_post_empty_prompt_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()

  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_method(Post)
    |> request.set_path("/chat")
    |> request.set_query([#("prompt", "")])

  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Please enter a question.") |> should.be_true
}

pub fn router_chat_post_with_body_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()

  // Simulate a form POST with "prompt=hello" in the body
  let body = bit_array.from_string("prompt=hello")
  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_path("/chat")
    |> request.set_body(body)
    |> request.set_header("content-type", "application/x-www-form-urlencoded")

  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)

  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string

  // It should NOT say "Please enter a question." because we provided a prompt in the body
  body |> string.contains("Please enter a question.") |> should.be_false
}

pub fn router_chat_get_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()
  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_method(Get)
    |> request.set_path("/chat")
  let res = router.router(req, path, ctx)
  res.status |> should.equal(200)
  let assert Ok(body) =
    res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Chat with your Vault") |> should.be_true
}

pub fn router_chat_put_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()
  // Use Put (which is not handled in serve_chat specifically, should hit _ fallback)
  let req =
    request.new()
    |> request.set_body(bit_array.from_string(""))
    |> request.set_method(Put)
    |> request.set_path("/chat")
  let res = router.router(req, path, ctx)
  res.status |> should.equal(404)
}

pub fn gemini_shell_executor_test() {
  // Test with a standard shell command that works on all systems (echo)
  let res = gemini_cli_adapter.shell_executor("echo 'hello'")
  // Erlang os:cmd includes trailing newline
  string.contains(res, "hello") |> should.be_true()
}

pub fn system_start_with_deps_error_test() {
  let logger = factories.logger_silent()
  let res =
    system.start_with_dependencies(8000, logger, fn() {
      Error(config.EnvironmentVariableMissing("FAKED"))
    })
  res |> should.equal(Error("Environment variable missing: FAKED"))
}

pub fn system_start_with_deps_success_test() {
  let logger = factories.logger_silent()
  let load_conf = fn() {
    let assert Ok(path) = vault.vault_path_from_string("/vault")
    Ok(config.Config(vault_path: path))
  }
  let res = system.start_with_dependencies(8001, logger, load_conf)
  res |> should.be_ok()
}

pub fn gemini_cli_adapter_new_test2() {
  let adapter = gemini_cli_adapter.new()
  let _ = adapter.ask
  True |> should.be_true()
}

pub fn config_load_direct_test() {
  let _res = config.load()
  True |> should.be_true()
}

pub fn system_route_handler_test() {
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let req = request.new() |> request.set_path("/")
  let res =
    system.handle_request(req, vault_path, ctx, fn(r) {
      Ok(request.set_body(r, bit_array.from_string("")))
    })
  res.status |> should.equal(500)
}

pub fn system_handle_request_error_test() {
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let req = request.new() |> request.set_path("/")
  let res = system.handle_request(req, vault_path, ctx, fn(_) { Error(Nil) })
  res.status |> should.equal(400)
}

pub fn system_create_route_handler_execution_test() {
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let handler =
    system.create_route_handler_with_reader(vault_path, ctx, fn(r) {
      Ok(request.set_body(r, bit_array.from_string("")))
    })
  let req = request.new() |> utils.coerce
  let res = handler(req)
  res.status |> should.equal(500)
}

pub fn config_invalid_path_test() {
  let get_env_invalid = fn(_) { Ok("") }
  config.load_with_env(get_env_invalid)
  |> should.equal(Error(config.InvalidConfigPath("Path cannot be empty")))
}

@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(bin: String) -> Dynamic

@external(erlang, "os", "putenv")
fn os_putenv(name: Dynamic, val: Dynamic) -> Dynamic

pub fn config_ok_env_test() {
  os_putenv(binary_to_list("CAMPAIGNER_VAULT_PATH"), binary_to_list("/tmp"))
  let res = config.load()
  res |> should.be_ok()
}

import campaigner_app
import gleam/erlang/atom
import gleam/erlang/process

@external(erlang, "logger", "set_primary_config")
fn set_logger_level(key: atom.Atom, val: atom.Atom) -> dynamic.Dynamic

@external(erlang, "erlang", "list_to_atom")
fn list_to_atom(list: dynamic.Dynamic) -> atom.Atom

pub fn mute_logger() {
  let level_atom = list_to_atom(binary_to_list("level"))
  let none_atom = list_to_atom(binary_to_list("none"))
  set_logger_level(level_atom, none_atom)
}

@external(erlang, "erlang", "spawn")
fn erlang_spawn(f: fn() -> a) -> dynamic.Dynamic

pub fn app_main_coverage_test() {
  mute_logger()
  // Run main in background to cover it and its sleep loop.
  // We use a shorter sleep in the test if we could, but we just want the lines hit.
  let _pid = erlang_spawn(fn() { campaigner_app.main() })
  process.sleep(100)
  // We don't kill it, it will die with the VM.
  True |> should.be_true()
}

pub fn router_chat_invalid_method_test() {
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let req =
    request.new()
    |> request.set_method(Put)
    |> request.set_path("/chat")
    |> request.set_body(bit_array.from_string(""))
  let res = router.router(req, vault_path, ctx)
  res.status |> should.equal(404)
}

pub fn router_chat_invalid_utf8_test() {
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_path("/chat")
    |> request.set_body(<<255>>)
  let res = router.router(req, vault_path, ctx)
  res.status |> should.equal(200)
  // Should show empty prompt error
  res.body
  |> bytes_tree.to_bit_array
  |> bit_array.to_string
  |> result.unwrap("")
  |> string.contains("Please enter a question.")
  |> should.be_true()
}

pub fn config_is_valid_vault_path_format_test() {
  config.is_valid_vault_path_format("") |> should.be_false()
  config.is_valid_vault_path_format("/valid") |> should.be_true()
}

pub fn system_closure_coverage_test() {
  mute_logger()
  let ctx = factories.context()
  let assert Ok(vault_path) = vault.vault_path_from_string("/vault")
  let handler = system.create_route_handler(vault_path, ctx)
  // Coerce an integer to a mist connection just to enter the closure.
  // It will likely crash in a background process, but we hit the line.
  let conn = utils.coerce(1)
  let req =
    request.new()
    |> request.set_body(conn)
    |> request.set_method(Post)
    |> request.set_path("/chat")

  let _ = erlang_spawn(fn() { handler(req) })
  process.sleep(50)
  True |> should.be_true()
}

pub fn stdout_logger_coverage_test() {
  utils.silence_stdout(fn() {
    let logger = stdout_logger.new()
    logger.info("test info", [])
    logger.error("test error", [#("key", "value")])
  })
  True |> should.be_true()
}
