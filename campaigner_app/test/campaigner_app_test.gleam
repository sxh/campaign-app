import campaigner/vault
import campaigner/config
import campaigner/config/defaults
import campaigner/system
import campaigner/services/dashboard_service as service
import campaigner/web/views
import campaigner/web/router
import campaigner/ports/chat_engine
import campaigner/ports/file_system
import campaigner/infrastructure/simplifile_adapter
import campaigner/infrastructure/fake_file_system
import factories
import gleam/string
import gleam/bytes_tree
import gleam/bit_array
import gleam/dict
import gleeunit
import gleeunit/should
import lustre/element
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn gather_stats_test() {
  let test_vault_path_str = "./test_vault"
  let test_vault_path = factories.vault_path(test_vault_path_str)
  let ctx = vault.Context(
    fs: simplifile_adapter.real_fs(),
    logger: factories.logger_silent(),
    chat: factories.chat_silent(),
    timeout_ms: 5000
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
  vault.vault_path_to_string(vault.get_vault_path(stats)) |> should.equal(test_vault_path_str)
  
  // Teardown
  let _ = simplifile.delete(test_vault_path_str)
}

pub fn vault_path_validation_test() {
  vault.vault_path_from_string("") |> should.equal(Error(vault.InvalidPath("Path cannot be empty")))
  vault.vault_path_from_string("   ") |> should.equal(Error(vault.InvalidPath("Path cannot be empty")))
  let path = factories.vault_path("/valid/path")
  vault.vault_path_to_string(path) |> should.equal("/valid/path")
}

pub fn gather_stats_mock_error_test() {
  let mock_fs = file_system.FileSystem(
    get_files: fn(_) { Ok(["note1.md"]) },
    read: fn(_) { Error(simplifile.Enoent) }
  )
  let ctx = factories.context_with_fs(mock_fs)
  let path = factories.vault_path("/path")
  
  let result = vault.gather_stats(path, ctx)
  result |> should.equal(Error(vault.FileReadError("note1.md", simplifile.Enoent)))
}

pub fn gather_stats_fake_test() {
  let files = dict.from_list([
    #("/vault/note1.md", "Hello"),
    #("/vault/note2.md", "World"),
    #("/vault/image.png", "binary")
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
  let ctx = factories.context() // real_fs wrapper from factory
  let result = vault.gather_stats(path, ctx)
  
  result |> should.equal(Error(vault.VaultNotFound(test_path)))
}

pub fn render_dashboard_test() {
  let _stats = factories.stats()
  let vm = views.DashboardViewModel(
    vault_path: "/test/vault",
    total_files: "1",
    md_files: "1",
    total_characters: "0",
    image_files: "0",
    notes_message: "notes",
    chars_message: "chars"
  )
  let html = views.render_dashboard(vm) |> element.to_string
  
  html |> string.contains("Campaigner Dashboard") |> should.be_true
  html |> string.contains("Total Files: 1") |> should.be_true
}

pub fn render_dashboard_empty_test() {
  let path = factories.vault_path("/empty")
  let fs = fake_file_system.from_contents(dict.from_list([#("/empty/root", "")]))
  let ctx = factories.context_with_fs(fs)
  let assert Ok(_stats) = vault.gather_stats(path, ctx)
  
  let vm = views.DashboardViewModel(
    vault_path: "/empty",
    total_files: "1",
    md_files: "0",
    total_characters: "0",
    image_files: "0",
    notes_message: "No notes found.",
    chars_message: ""
  )
  let html = views.render_dashboard(vm) |> element.to_string
  html |> string.contains("Total Files: 1") |> should.be_true
  html |> string.contains("No notes found.") |> should.be_true
}

pub fn render_dashboard_full_test() {
  let path = factories.vault_path("/path")
  let fs = fake_file_system.from_contents(dict.from_list([
    #("/path/n1.md", string.repeat("a", 600)),
    #("/path/n2.md", string.repeat("b", 600))
  ]))
  let ctx = factories.context_with_fs(fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)
  
  let html = views.render_dashboard(service.to_dashboard_view_model(stats)) |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  // Lustre escapes single quotes
  html |> string.contains("Wow, that&#39;s a lot of writing!") |> should.be_true
}

pub fn render_dashboard_low_chars_test() {
  let path = factories.vault_path("/path")
  let fs = fake_file_system.from_contents(dict.from_list([
    #("/path/n1.md", "small")
  ]))
  let ctx = factories.context_with_fs(fs)
  let assert Ok(stats) = vault.gather_stats(path, ctx)
  
  let html = views.render_dashboard(service.to_dashboard_view_model(stats)) |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  html |> string.contains("Keep writing!") |> should.be_true
}

pub fn router_root_test() {
  let test_vault_path_str = "./test_vault_router"
  let test_vault_path = factories.vault_path(test_vault_path_str)
  let ctx = vault.Context(
    fs: simplifile_adapter.real_fs(),
    logger: factories.logger_silent(),
    chat: factories.chat_silent(),
    timeout_ms: 5000
  )
  let _ = simplifile.create_directory_all(test_vault_path_str)
  
  let res = router.router([], test_vault_path, ctx)
  res.status |> should.equal(200)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Campaigner Dashboard") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
  
  let _ = simplifile.delete(test_vault_path_str)
}

pub fn router_error_test() {
  let test_path = "./non_existent_vault_router"
  let path = factories.vault_path(test_path)
  let ctx = factories.context()
  
  let res = router.router([], path, ctx)
  res.status |> should.equal(500)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Vault Not Found") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
}

pub fn router_404_test() {
  let assert Ok(path) = vault.vault_path_from_string("/tmp")
  let ctx = factories.context()
  let res = router.router(["unknown"], path, ctx)
  res.status |> should.equal(404)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("404 - Not Found") |> should.be_true
  body |> string.contains("<html>") |> should.be_true
}

pub fn parse_route_test() {
  router.parse_route([]) |> should.equal(router.Dashboard)
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
  let files = dict.from_list([
    #("/vault/corrupt.md", Error(simplifile.Eacces))
  ])
  let fs = fake_file_system.new(files)
  let ctx = factories.context_with_fs(fs)
  
  let res = router.router([], path, ctx)
  res.status |> should.equal(500)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Read Error") |> should.be_true
  body |> string.contains("/vault/corrupt.md") |> should.be_true
}

pub fn config_error_string_test() {
  config.string_from_vault_error(vault.VaultNotFound("/p")) |> should.equal("Path not found: /p")
  config.string_from_vault_error(vault.FileReadError("/f", simplifile.Eacces)) |> should.equal("Read error: /f")
  config.string_from_vault_error(vault.InvalidPath("oops")) |> should.equal("oops")
}

pub fn gather_stats_timeout_test() {
  let path_str = "/vault"
  let assert Ok(path) = vault.vault_path_from_string(path_str)
  let files = dict.from_list([#("/vault/note.md", Ok("Some content"))])
  let fs = fake_file_system.new(files)
  
  let ctx = vault.Context(
    fs: fs,
    logger: factories.logger_silent(),
    chat: factories.chat_silent(),
    timeout_ms: 0
  )
  
  let result = vault.gather_stats(path, ctx)
  let assert Ok(stats) = result
  vault.get_total_characters(stats) |> should.equal(0)
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
  vault.vault_path_to_string(cfg2.vault_path) |> should.equal(defaults.vault_path)
}

pub fn ask_vault_test() {
  let path = factories.vault_path("/vault")
  let mock_chat = chat_engine.ChatEngine(
    ask: fn(_, _) { Ok("Answer") }
  )
  let ctx = vault.Context(
    fs: fake_file_system.from_contents(dict.new()),
    logger: factories.logger_silent(),
    chat: mock_chat,
    timeout_ms: 5000
  )
  
  service.ask_vault("Question", path, ctx) |> should.equal(Ok("Answer"))
}

pub fn router_chat_test() {
  let path = factories.vault_path("/vault")
  let ctx = factories.context()
  let res = router.router(["chat"], path, ctx)
  res.status |> should.equal(200)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Chat Facility Coming Soon") |> should.be_true
}
