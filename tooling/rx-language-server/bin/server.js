#!/usr/bin/env node
// The .rx language server over stdio (or whatever transport the client asks for): Volar's TypeScript project with the
// .rx language plugin, TypeScript's services, and the crate's diagnostics.
const { createConnection, createServer, createTypeScriptProject, loadTsdkByPath } = require("@volar/language-server/node");
const fs = require("node:fs");
const path = require("node:path");
const { fileURLToPath } = require("node:url");
const { create: createTypeScriptServices } = require("volar-service-typescript");
const { rxLanguagePlugin, rxDiagnostics } = require("../src/index.js");

/** TypeScript's lib folder: the client's, else the nearest `node_modules/typescript` at or above a workspace folder
 * (a hoisted workspace's), else our own. Walks the folders itself: require.resolve would also try global folders. */
function tsdkFor(params) {
  const given = params.initializationOptions?.typescript?.tsdk;
  if (given) return given;
  const folders = params.workspaceFolders?.map(f => f.uri) ?? (params.rootUri ? [params.rootUri] : []);
  for (const uri of folders) {
    if (!uri.startsWith("file:")) continue;
    for (let dir = fileURLToPath(uri); ; dir = path.dirname(dir)) {
      const lib = path.join(dir, "node_modules", "typescript", "lib");
      if (fs.existsSync(path.join(lib, "typescript.js"))) return lib;
      if (path.dirname(dir) === dir) break;
    }
  }
  return path.dirname(require.resolve("typescript"));
}

const connection = createConnection();
const server = createServer(connection);

connection.listen();

connection.onInitialize(params => {
  const tsdk = loadTsdkByPath(tsdkFor(params), params.locale);
  return server.initialize(
    params,
    createTypeScriptProject(tsdk.typescript, tsdk.diagnosticMessages, () => ({ languagePlugins: [rxLanguagePlugin(tsdk.typescript)] })),
    [...createTypeScriptServices(tsdk.typescript), rxDiagnostics()],
  );
});

connection.onInitialized(server.initialized);
connection.onShutdown(server.shutdown);
