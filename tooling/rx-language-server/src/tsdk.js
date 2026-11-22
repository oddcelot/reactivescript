// Which TypeScript the server loads (spec/11 CP-8): the client's, else the project's, else our own.
const fs = require("node:fs");
const path = require("node:path");
const { fileURLToPath } = require("node:url");

/** TypeScript's lib folder: the client's, else the nearest `node_modules/typescript` at or above a workspace folder
 * (a hoisted workspace's), up to the repository root (the dir holding `.git`), else our own. Walks the folders itself:
 * require.resolve would also try global folders. */
function tsdkFor(params) {
  const given = params.initializationOptions?.typescript?.tsdk;
  if (given) return given;
  const folders = params.workspaceFolders?.length ? params.workspaceFolders.map(f => f.uri) : params.rootUri ? [params.rootUri] : [];
  for (const uri of folders) {
    if (!uri.startsWith("file:")) continue;
    let start;
    try {
      start = fileURLToPath(uri); // throws on some valid file URIs (a host, an encoded slash): skip the folder
    } catch {
      continue;
    }
    for (let dir = start; ; dir = path.dirname(dir)) {
      const lib = path.join(dir, "node_modules", "typescript", "lib");
      if (fs.existsSync(path.join(lib, "typescript.js"))) return lib;
      if (fs.existsSync(path.join(dir, ".git"))) break; // the repository root (a worktree's `.git` is a file)
      if (path.dirname(dir) === dir) break;
    }
  }
  return path.dirname(require.resolve("typescript"));
}

module.exports = { tsdkFor };
