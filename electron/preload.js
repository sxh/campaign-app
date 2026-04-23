const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("opencodeAPI", {
  createSession: (baseUrl) =>
    fetch(baseUrl, { method: "POST" }).then((r) => r.json()).then((d) => d.slug),
});
