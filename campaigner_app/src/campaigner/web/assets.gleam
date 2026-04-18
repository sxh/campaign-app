import lustre/element.{type Element}
import lustre/element/html

pub fn global_styles() -> Element(msg) {
  html.style([], "
    body {
      font-family: sans-serif;
      line-height: 1.5;
      color: #333;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      background-color: #f4f4f9;
    }
    h1 { color: #2c3e50; }
    code {
      background-color: #eee;
      padding: 0.2rem 0.4rem;
      border-radius: 3px;
    }
    ul { list-style-type: none; padding: 0; }
    li { margin-bottom: 0.5rem; padding: 0.5rem; background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    footer { margin-top: 2rem; font-size: 0.8rem; color: #777; border-top: 1px solid #ddd; padding-top: 1rem; }
    .error { color: #e74c3c; }
    a { color: #3498db; text-decoration: none; }
    a:hover { text-decoration: underline; }
  ")
}
