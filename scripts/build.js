import fs from "fs";
import path from "path";

const root = process.cwd();
const buildDir = path.join(root, "build", "dev", "javascript");
const destDir = path.join(root, "public");

for (const f of fs.readdirSync(destDir)) {
  if (f === "index.html") continue;
  fs.rmSync(path.join(destDir, f), { recursive: true, force: true });
}

const seen = new Set();
function collect(filePath) {
  if (seen.has(filePath)) return;
  seen.add(filePath);
  const content = fs.readFileSync(filePath, "utf-8");
  for (const m of content.matchAll(/from\s+"([^"]+)"/g)) {
    const importPath = m[1];
    if (importPath.startsWith(".")) {
      const resolved = path.resolve(path.dirname(filePath), importPath);
      if (fs.existsSync(resolved)) {
        collect(resolved);
      }
    }
  }
}

// Collect campaigner_app and campaigner_app_main
const appDir = path.join(buildDir, "campaigner_app");
collect(path.join(appDir, "campaigner_app.mjs"));
collect(path.join(appDir, "campaigner_app_main.mjs"));

// Also collect lustre
const lustreDir = path.join(buildDir, "lustre");
collect(path.join(lustreDir, "lustre.mjs"));

const moduleDir = path.join(destDir, "_gleam_modules");
for (const f of seen) {
  const rel = path.relative(buildDir, f);
  const dest = path.join(moduleDir, rel);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.cpSync(f, dest);
}

for (const f of seen) {
  const rel = path.relative(buildDir, f);
  const dest = path.join(moduleDir, rel);
  let content = fs.readFileSync(dest, "utf-8");
  content = content.replace(/from\s+"([^"]+)"/g, (match, importPath) => {
    if (!importPath.startsWith(".")) return match;
    const resolved = path.resolve(path.dirname(f), importPath);
    if (seen.has(resolved)) {
      const importRel = path.relative(buildDir, resolved);
      const fromRel = path.dirname(rel);
      const relPath = path.relative(fromRel, importRel);
      return `from "${relPath.startsWith(".") ? relPath : "./" + relPath}"`;
    }
    return match;
  });
  fs.writeFileSync(dest, content);
}

// Copy campaigner_app_main.mjs to public root as entry point
const mainRel = path.join("_gleam_modules", path.relative(buildDir, path.join(appDir, "campaigner_app_main.mjs")));
let mainContent = fs.readFileSync(path.join(destDir, mainRel), "utf-8");
mainContent = mainContent.replace(/from\s+"([^"]+)"/g, (match, importPath) => {
  if (!importPath.startsWith(".")) return match;
  const resolved = path.resolve(path.join(destDir, path.dirname(mainRel)), importPath);
  const rel = path.relative(destDir, resolved);
  return `from "./${rel}"`;
});
fs.writeFileSync(path.join(destDir, "campaigner_app_main.mjs"), mainContent);

console.log("Build complete");
