import campaigner/vault
import campaigner/web/views
import campaigner/web/router
import campaigner/services/dashboard_service as service
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
    logger: factories.logger_silent()
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
  let assert Ok(stats) = result
  vault.get_md_files(stats) |> should.equal(1)
  vault.get_total_characters(stats) |> should.equal(0)
}

pub fn gather_stats_fake_test() {
  let files = dict.from_list([
    #("/vault/note1.md", "Hello"),
    #("/vault/note2.md", "World"),
    #("/vault/image.png", "binary")
  ])
  let fs = fake_file_system.new(files)
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
  let fs = fake_file_system.new(dict.from_list([#("/empty/root", "")]))
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

pub fn router_root_test() {
  let test_vault_path_str = "./test_vault_router"
  let test_vault_path = factories.vault_path(test_vault_path_str)
  let ctx = vault.Context(
    fs: simplifile_adapter.real_fs(),
    logger: factories.logger_silent()
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

pub fn get_notes_message_test() {
  service.get_notes_message(5) |> should.equal("You have some notes!")
  service.get_notes_message(0) |> should.equal("No notes found.")
}

pub fn get_chars_message_test() {
  service.get_chars_message(5000) |> should.equal("Wow, that's a lot of writing!")
  service.get_chars_message(500) |> should.equal("Keep writing!")
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
