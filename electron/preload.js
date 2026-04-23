const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("opencodeAPI", {
  encodeBase64: (str) => Buffer.from(str, "utf-8").toString("base64"),
  createSession: (baseUrl, directory) =>
    fetch(baseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-opencode-directory": directory,
      },
    })
      .then((r) => {
        if (!r.ok) throw new Error(`Server returned ${r.status} ${r.statusText}`);
        return r.json();
      })
      .then((d) => d.id),
});
