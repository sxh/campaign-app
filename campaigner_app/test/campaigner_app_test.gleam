import campaigner_app
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn gather_stats_test() {
  let test_vault_path = "./test_vault"
  
  // Setup
  let _ = simplifile.create_directory_all(test_vault_path)
  let _ = simplifile.write(test_vault_path <> "/note1.md", "Hello")
  let _ = simplifile.write(test_vault_path <> "/note2.md", "World!")
  let _ = simplifile.write(test_vault_path <> "/image.png", "fake data")
  let _ = simplifile.write(test_vault_path <> "/other.txt", "ignore me")
  
  // Execute
  let stats = campaigner_app.gather_stats(test_vault_path)
  
  // Assert
  stats.total_files |> should.equal(4)
  stats.md_files |> should.equal(2)
  stats.image_files |> should.equal(1)
  stats.total_characters |> should.equal(11) // "Hello" (5) + "World!" (6)
  stats.vault_path |> should.equal(test_vault_path)
  
  // Teardown
  let _ = simplifile.delete(test_vault_path)
}

pub fn render_dashboard_test() {
  let stats = campaigner_app.Stats(
    total_files: 10,
    md_files: 5,
    image_files: 2,
    total_characters: 100,
    vault_path: "/test/vault"
  )
  
  let html = campaigner_app.render_dashboard(stats) |> element.to_string
  
  html |> string.contains("Campaigner Dashboard") |> should.be_true
  html |> string.contains("Total Files: 10") |> should.be_true
  html |> string.contains("Markdown Notes: 5") |> should.be_true
  html |> string.contains("Images: 2") |> should.be_true
  html |> string.contains("Total Characters in Notes: 100") |> should.be_true
  html |> string.contains("/test/vault") |> should.be_true
}
