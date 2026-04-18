import campaigner_app
import campaigner/vault
import campaigner/web/views
import gleam/string
import gleam/bytes_tree
import gleam/bit_array
import gleam/http/request
import gleeunit
import gleeunit/should
import lustre/element
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn gather_stats_test() {
  let test_vault_path_str = "./test_vault"
  let test_vault_path = vault.vault_path_from_string(test_vault_path_str)
  let ctx = vault.Context(fs: vault.real_fs())
  
  // Setup
  let _ = simplifile.create_directory_all(test_vault_path_str)
  let _ = simplifile.write(test_vault_path_str <> "/note1.md", "Hello")
  let _ = simplifile.write(test_vault_path_str <> "/note2.md", "World!")
  let _ = simplifile.write(test_vault_path_str <> "/image.png", "fake data")
  let _ = simplifile.write(test_vault_path_str <> "/other.txt", "ignore me")
  
  // Execute
  let stats = vault.gather_stats(test_vault_path, ctx)
  
  // Assert
  stats.total_files |> should.equal(4)
  stats.md_files |> should.equal(2)
  stats.image_files |> should.equal(1)
  stats.total_characters |> should.equal(11) // "Hello" (5) + "World!" (6)
  vault.vault_path_to_string(stats.vault_path) |> should.equal(test_vault_path_str)
  
  // Teardown
  let _ = simplifile.delete(test_vault_path_str)
}

pub fn gather_stats_mock_error_test() {
  let mock_fs = vault.FileSystem(
    get_files: fn(_) { Ok(["note1.md"]) },
    read: fn(_) { Error(simplifile.Enoent) }
  )
  let ctx = vault.Context(fs: mock_fs)
  let path = vault.vault_path_from_string("/path")
  
  let stats = vault.gather_stats(path, ctx)
  stats.md_files |> should.equal(1)
  stats.total_characters |> should.equal(0) // Error branch hit
}

pub fn gather_stats_error_test() {
  let path = vault.vault_path_from_string("./non_existent_vault")
  let ctx = vault.Context(fs: vault.real_fs())
  let stats = vault.gather_stats(path, ctx)
  stats.total_files |> should.equal(0)
}

pub fn render_dashboard_test() {
  let path = vault.vault_path_from_string("/test/vault")
  let stats = vault.Stats(
    total_files: 10,
    md_files: 5,
    image_files: 2,
    total_characters: 100,
    vault_path: path
  )
  
  let html = views.render_dashboard(stats) |> element.to_string
  
  html |> string.contains("Campaigner Dashboard") |> should.be_true
  html |> string.contains("Total Files: 10") |> should.be_true
  html |> string.contains("Markdown Notes: 5") |> should.be_true
  html |> string.contains("Total Characters in Notes: 100") |> should.be_true
  html |> string.contains("/test/vault") |> should.be_true
}

pub fn render_dashboard_empty_test() {
  let path = vault.vault_path_from_string("")
  let stats = vault.Stats(0, 0, 0, 0, path)
  let html = views.render_dashboard(stats) |> element.to_string
  html |> string.contains("Total Files: 0") |> should.be_true
  html |> string.contains("No notes found.") |> should.be_true
}

pub fn render_dashboard_full_test() {
  let path = vault.vault_path_from_string("/path")
  let stats = vault.Stats(
    total_files: 100, 
    md_files: 50, 
    image_files: 10, 
    total_characters: 5000, 
    vault_path: path
  )
  let html = views.render_dashboard(stats) |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  // Lustre escapes single quotes
  html |> string.contains("Wow, that&#39;s a lot of writing!") |> should.be_true
}

pub fn render_dashboard_low_chars_test() {
  let path = vault.vault_path_from_string("/path")
  let stats = vault.Stats(
    total_files: 1, 
    md_files: 1, 
    image_files: 0, 
    total_characters: 500, 
    vault_path: path
  )
  let html = views.render_dashboard(stats) |> element.to_string
  html |> string.contains("You have some notes!") |> should.be_true
  html |> string.contains("Keep writing!") |> should.be_true
}

pub fn router_root_test() {
  let test_vault_path_str = "./test_vault_router"
  let test_vault_path = vault.vault_path_from_string(test_vault_path_str)
  let ctx = vault.Context(fs: vault.real_fs())
  let _ = simplifile.create_directory_all(test_vault_path_str)
  
  let res = campaigner_app.router([], test_vault_path, ctx)
  res.status |> should.equal(200)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> string.contains("Campaigner Dashboard") |> should.be_true
  
  let _ = simplifile.delete(test_vault_path_str)
}

pub fn router_404_test() {
  let path = vault.vault_path_from_string("/tmp")
  let ctx = vault.Context(fs: vault.real_fs())
  let res = campaigner_app.router(["unknown"], path, ctx)
  res.status |> should.equal(404)
  
  let assert Ok(body) = res.body |> bytes_tree.to_bit_array |> bit_array.to_string
  body |> should.equal("Not Found")
}

pub fn handle_connection_test() {
  let req = request.new()
  let path = vault.vault_path_from_string("/tmp")
  let ctx = vault.Context(fs: vault.real_fs())
  let res = campaigner_app.handle_connection(req, path, ctx)
  res.status |> should.equal(200)
}

pub fn get_notes_message_test() {
  views.get_notes_message(5) |> should.equal("You have some notes!")
  views.get_notes_message(0) |> should.equal("No notes found.")
}

pub fn get_chars_message_test() {
  views.get_chars_message(5000) |> should.equal("Wow, that's a lot of writing!")
  views.get_chars_message(500) |> should.equal("Keep writing!")
}

pub fn is_markdown_test() {
  vault.is_markdown("test.md") |> should.be_true
  vault.is_markdown("test.txt") |> should.be_false
}

pub fn is_image_test() {
  vault.is_image("test.png") |> should.be_true
  vault.is_image("test.jpg") |> should.be_true
  vault.is_image("test.jpeg") |> should.be_true
  vault.is_image("test.txt") |> should.be_false
}

pub fn real_fs_test() {
  let fs = vault.real_fs()
  // Just verify it returns the record with functions
  let _ = fs.get_files
  let _ = fs.read
  True |> should.be_true
}
