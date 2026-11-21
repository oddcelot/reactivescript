# ReactiveScript for Zed

Highlighting for `.rx` and `.d.rx` from a Tree-sitter grammar
([`../tree-sitter-rx`](../tree-sitter-rx)), and, through the `.rx` language server
([`../rx-language-server`](../rx-language-server)), TypeScript's hover, go to
definition, references, rename, completion and type errors, plus the
compiler's own diagnostics. ` ```rx ` and ` ```reactivescript ` blocks in
Markdown use the same language.

The extension installs `@reactivescript/language-server` from npm (and updates it
when a newer release exists; offline it keeps the installed copy) and runs it
with Zed's Node over stdio.

The project needs a `tsconfig.json` with Solid's JSX (`"jsx": "preserve"`,
`"jsxImportSource": "@solidjs/web"`) and `@solidjs/web` in its `node_modules`;
the server writes the projection's prelude to `node_modules/.reactivescript/`.
It uses the worktree's `node_modules/typescript`, else its own TypeScript.

## Installing as a dev extension

Run **zed: install dev extension** in the command palette and pick this folder
(`tooling/zed-rx`). Zed needs Rust (via rustup) to build the extension, and
fetches and compiles the grammar named in `extension.toml`. For local work,
point `[grammars.rx]`'s `repository` at a checkout with the grammar committed
(`file:///path/to/reactivescript`) and `rev` at that commit.

## Settings

All under `lsp.rx-language-server` in Zed's `settings.json`:

```json
{
  "lsp": {
    "rx-language-server": {
      "settings": {
        "rxc": { "path": "/path/to/reactivescript/compiler/target/release/rxc" },
        "typescript": { "tsdk": "/path/to/project/node_modules/typescript/lib" }
      }
    }
  }
}
```

- `settings.rxc.path`: an `rxc` binary for the server to run per request
  instead of its bundled WebAssembly build (sets `RXC`).
- `settings.typescript.tsdk`: TypeScript's `lib` folder. Unset: the worktree's
  `node_modules/typescript/lib` if there is one (the worktree root only, not a
  parent workspace's), else the server's own.
- `initialization_options`: merged over what the extension sends
  (`{ "typescript": { "tsdk": … } }`).

To run another server instead of the npm package, such as this repository's,
set `binary`. Zed then starts that command itself, without the extension: it
adds no `--stdio`, does not run a `.js` file with its Node, and does not read
`settings.rxc.path`, so name all three:

```json
{
  "lsp": {
    "rx-language-server": {
      "binary": {
        "path": "node",
        "arguments": ["/path/to/reactivescript/tooling/rx-language-server/bin/server.js", "--stdio"],
        "env": { "RXC": "/path/to/reactivescript/compiler/target/release/rxc" }
      }
    }
  }
}
```

`binary.env` without a `path` is added to the npm server's environment.
`binary.arguments` without a `path` replaces the extension's arguments (the
server's path and `--stdio`), so set it only together with a `path`.

The server's semantic tokens only show once Zed asks for them; they are off by
default:

```json
{ "languages": { "ReactiveScript": { "semantic_tokens": "combined" } } }
```
