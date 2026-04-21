pub fn css() -> String {
  "
    :root {
      --primary: #5a5ef0;
      --primary-hover: #484dc9;
      --bg: #f8f9fa;
      --text: #212529;
      --white: #ffffff;
      --gray: #6c757d;
      --border: #dee2e6;
      --error: #dc3545;
      
      /* Terminal colors */
      --terminal-bg: #1e1e1e;
      --terminal-header-bg: #2d2d2d;
      --terminal-border: #404040;
      --terminal-text: #f0f0f0;
      --terminal-muted: #aaa;
      --terminal-prompt: #4caf50;
      --terminal-path: #4fc3f7;
      --terminal-command: #ff9800;
      --terminal-font: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
    }

    body {
      font-family: system-ui, -apple-system, sans-serif;
      line-height: 1.5;
      color: var(--text);
      background-color: var(--bg);
      margin: 0;
      padding: 0;
    }

    .container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 0 20px;
    }

    .navbar {
      background-color: var(--white);
      border-bottom: 1px solid var(--border);
      padding: 15px 0;
      margin-bottom: 30px;
    }

    .navbar .container {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .nav-brand {
      font-size: 1.5rem;
      font-weight: bold;
      color: var(--primary);
      text-decoration: none;
    }

    .nav-links {
      display: flex;
      gap: 20px;
    }

    .nav-link {
      color: var(--text);
      text-decoration: none;
      font-weight: 500;
    }

    .nav-link:hover {
      color: var(--primary);
    }

    .dashboard h1 { margin-bottom: 10px; }
    .vault-path { color: var(--gray); margin-bottom: 30px; }
    .vault-path code { background: #eee; padding: 2px 5px; border-radius: 3px; }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 40px;
    }

    .stat-card {
      background: var(--white);
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      border: 1px solid var(--border);
    }

    .stat-card h2 {
      font-size: 0.9rem;
      text-transform: uppercase;
      color: var(--gray);
      margin-bottom: 10px;
    }

    .stat-value {
      font-size: 2rem;
      font-weight: bold;
      margin: 0;
      color: var(--primary);
    }

    .stat-message {
      font-size: 0.85rem;
      color: var(--gray);
      margin-top: 5px;
    }

    .actions {
      text-align: center;
    }

    .btn-primary {
      display: inline-block;
      background-color: var(--primary);
      color: var(--white);
      padding: 12px 24px;
      border-radius: 6px;
      text-decoration: none;
      font-weight: bold;
      transition: background-color 0.2s;
    }

    .btn-primary:hover {
      background-color: var(--primary-hover);
    }

    .chat-container {
      background: var(--white);
      padding: 30px;
      border-radius: 12px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.05);
      max-width: 800px;
      margin: 0 auto;
    }

    .chat-form {
      margin: 20px 0;
    }

    .chat-input {
      width: 100%;
      min-height: 120px;
      padding: 15px;
      border: 1px solid var(--border);
      border-radius: 8px;
      font-size: 1rem;
      resize: vertical;
      box-sizing: border-box;
      margin-bottom: 15px;
    }
    .chat-input:disabled, .chat-input[readonly] {
      background-color: #f8f9fa;
      cursor: not-allowed;
      opacity: 0.7;
    }

    .btn-submit {
      background-color: var(--primary);
      color: var(--white);
      border: none;
      padding: 12px 30px;
      border-radius: 6px;
      font-size: 1rem;
      font-weight: bold;
      cursor: pointer;
    }

    .btn-submit:hover {
      background-color: var(--primary-hover);
    }

    .spinner {
      display: none;
      inline-size: 1rem;
      block-size: 1rem;
      border: 2px solid rgba(255,255,255,0.3);
      border-radius: 50%;
      border-top-color: var(--white);
      animation: spin 1s ease-in-out infinite;
      margin-inline-end: 8px;
      vertical-align: middle;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .btn-submit.loading {
      opacity: 0.7;
      pointer-events: none;
    }

    .btn-submit.loading .spinner {
      display: inline-block;
    }

    .btn-submit.loading .btn-text {
      display: none;
    }
    .alert-error {
      background-color: #f8d7da;
      color: var(--error);
      padding: 15px;
      border-radius: 6px;
      margin: 20px 0;
    }

    .chat-response {
      margin-top: 40px;
      border-top: 2px solid var(--bg);
      padding-top: 30px;
    }

    .response-content {
      white-space: pre-wrap;
      background: #f1f3ff;
      padding: 20px;
      border-radius: 8px;
      border-left: 4px solid var(--primary);
    }

    .error-page { text-align: center; margin-top: 50px; }

    /* Terminal emulator styles */
    .terminal-container {
      background: var(--terminal-bg);
      border-radius: 8px;
      overflow: hidden;
      margin: 20px 0 30px 0;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }

    .terminal-header {
      background: var(--terminal-header-bg);
      padding: 12px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--terminal-border);
    }

    .terminal-title {
      color: var(--terminal-text);
      font-weight: bold;
      font-size: 0.9rem;
    }

    .terminal-path {
      color: var(--terminal-muted);
      font-size: 0.8rem;
    }

    .terminal-path code {
      background: var(--terminal-header-bg);
      color: var(--terminal-path);
      padding: 2px 6px;
      border-radius: 3px;
      font-family: var(--terminal-font);
    }

    .terminal-body {
      padding: 20px;
      font-family: var(--terminal-font);
      font-size: 0.9rem;
      line-height: 1.5;
      min-height: 120px;
    }

    .terminal-line {
      margin-bottom: 8px;
    }

    .terminal-prompt {
      color: var(--terminal-prompt);
      font-weight: bold;
      margin-right: 8px;
    }

    .terminal-command {
      color: var(--terminal-text);
    }

    .terminal-output {
      color: var(--terminal-muted);
      font-style: italic;
    }

    .terminal-command code {
      background: var(--terminal-header-bg);
      color: var(--terminal-command);
      padding: 1px 4px;
      border-radius: 2px;
    }
  "
}
