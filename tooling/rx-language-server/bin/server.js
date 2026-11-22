#!/usr/bin/env node
// The .rx language server over stdio (or whatever transport the client asks for): Volar's TypeScript project with the
// .rx language plugin, TypeScript's services, and the crate's diagnostics.
const { createConnection, createServer, createTypeScriptProject, loadTsdkByPath } = require("@volar/language-server/node");
const { create: createTypeScriptServices } = require("volar-service-typescript");
const { rxLanguagePlugin, rxDiagnostics } = require("../src/index.js");
const { tsdkFor } = require("../src/tsdk.js");

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
