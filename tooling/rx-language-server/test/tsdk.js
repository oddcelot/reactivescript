// Which TypeScript the server loads (src/tsdk.js), on temp trees: the client's tsdk, a hoisted `node_modules/typescript`
// above a workspace folder, the repository root as the end of the walk, a URI it can't read, `rootUri` as the fallback.
//   node test/tsdk.js
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { pathToFileURL } = require("node:url");
const { tsdkFor } = require("../src/tsdk.js");

let pass = 0, fail = 0;
function check(name, ok, got) {
  if (ok) pass++; else fail++;
  console.log(`${ok ? "  ✓" : "  ✗"} ${name}${ok ? "" : `\n      ${JSON.stringify(got)}`}`);
}

const own = path.dirname(require.resolve("typescript"));
const root = fs.mkdtempSync(path.join(os.tmpdir(), "rx-tsdk-"));
const dir = (...p) => { const d = path.join(root, ...p); fs.mkdirSync(d, { recursive: true }); return d; };
/** Puts a `node_modules/typescript/lib/typescript.js` in `d`; its lib folder. */
const withTs = d => { const lib = path.join(d, "node_modules", "typescript", "lib"); fs.mkdirSync(lib, { recursive: true }); fs.writeFileSync(path.join(lib, "typescript.js"), ""); return lib; };
const uri = d => ({ uri: pathToFileURL(d).href, name: "w" });
const folders = (...ds) => ({ workspaceFolders: ds.map(uri) });
/** The answer for `params`, and whether it threw. */
function ask(params) {
  try { return { got: tsdkFor(params), threw: false }; } catch { return { got: undefined, threw: true }; }
}

try {
  const hoisted = withTs(dir("hoist"));
  check("hoisted above a nested folder", tsdkFor(folders(dir("hoist", "packages", "app"))) === hoisted);
  const here = withTs(dir("here"));
  check("at the folder itself", tsdkFor(folders(dir("here"))) === here);
  check("explicit tsdk wins", tsdkFor({ ...folders(dir("hoist", "a")), initializationOptions: { typescript: { tsdk: "/x/lib" } } }) === "/x/lib");
  check("no TypeScript above: the server's own", tsdkFor(folders(dir("bare", "a"))) === own);

  withTs(dir("repo"));
  fs.mkdirSync(path.join(dir("repo", "pkg"), ".git"));
  check(".git between the folder and a hoisted TypeScript: stops", tsdkFor(folders(dir("repo", "pkg", "app"))) === own);
  const beside = withTs(dir("mono"));
  fs.mkdirSync(path.join(root, "mono", ".git"));
  check(".git beside the hoisted node_modules: still found", tsdkFor(folders(dir("mono", "app"))) === beside);
  fs.writeFileSync(path.join(dir("wt", "pkg"), ".git"), "gitdir: x\n");
  withTs(dir("wt"));
  check("a .git file (a worktree's) stops too", tsdkFor(folders(dir("wt", "pkg", "app"))) === own);

  let r = ask({ workspaceFolders: [{ uri: "untitled:Untitled-1", name: "u" }] });
  check("untitled: URI: no throw, the server's own", !r.threw && r.got === own, r);
  r = ask({ workspaceFolders: [{ uri: "file://server/share/x", name: "s" }] });
  check("file://server/share/x: no throw, the server's own", !r.threw && r.got === own, r);
  r = ask({ workspaceFolders: [{ uri: "file:///tmp/a%2Fb", name: "s" }, uri(dir("hoist", "n"))] });
  check("an unreadable folder is skipped, the next is tried", !r.threw && r.got === hoisted, r);

  check("empty workspaceFolders: rootUri", tsdkFor({ workspaceFolders: [], rootUri: uri(dir("hoist", "r")).uri }) === hoisted);
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
