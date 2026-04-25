const { app, BrowserWindow } = require("electron");
const path = require("path");
const fs = require("fs");

function getNoteCount(vaultPath) {
  try {
    const files = fs.readdirSync(vaultPath, { recursive: true });
    return files.filter(f => f.endsWith(".md")).length;
  } catch (e) {
    console.error("Error counting notes:", e);
    return 0;
  }
}

function createWindow() {
  const vaultPath = "/Users/steve.hayes/Library/Mobile Documents/iCloud~md~obsidian/Documents/ForgottenRealmsVault";
  const noteCount = getNoteCount(vaultPath);

  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  win.loadFile(path.join(__dirname, "..", "public", "index.html"), {
    query: {
      noteCount: noteCount.toString(),
    }
  });
}

app.whenReady().then(createWindow);

app.on("window-all-closed", () => {
  app.quit();
});

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
