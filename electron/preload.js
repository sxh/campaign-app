const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("opencodeAPI", {
  encodeBase64: (str) => Buffer.from(str, "utf-8").toString("base64"),
});
