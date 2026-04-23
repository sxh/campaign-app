import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const buildDir = path.join(__dirname, "build", "dev", "javascript");

function gleamPlugin() {
  return {
    name: "gleam",
    resolveId(source, importer) {
      if (source.endsWith(".mjs") && !source.startsWith(".")) {
        return path.join(buildDir, "campaigner_app", source);
      }
      return null;
    },
  };
}

export default {
  input: path.join(buildDir, "campaigner_app", "campaigner_app.mjs"),
  output: {
    file: path.join(__dirname, "public", "campaigner_app.mjs"),
    format: "es",
  },
  plugins: [gleamPlugin()],
};
