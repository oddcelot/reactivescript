//! Starts the ReactiveScript language server (`@reactivescript/language-server`) for Zed.
//!
//! The server is `lsp.rx-language-server.binary.path` when set, else the package installed from npm into
//! the extension's folder, run with Zed's Node over stdio.
//!
//! Settings, under `lsp.rx-language-server`:
//! - `binary.path` / `binary.arguments`: another server (a `.js` file runs with Zed's Node).
//! - `settings.rxc.path`: an `rxc` binary the server runs instead of its bundled WebAssembly build (`RXC`).
//! - `settings.typescript.tsdk`: TypeScript's `lib` folder. Default: the worktree's
//!   `node_modules/typescript/lib`, else the server's own TypeScript.
//! - `initialization_options`: merged over what this extension sends.

use zed_extension_api::{
    self as zed,
    serde_json::{json, Value},
    settings::LspSettings,
    LanguageServerId, Result,
};

const SERVER_ID: &str = "rx-language-server";
const PACKAGE: &str = "@reactivescript/language-server";
const BIN: &str = "bin/server.js";

struct RxExtension {
    /// The installed server's path, once checked this session.
    installed: Option<String>,
}

impl RxExtension {
    /// The installed copy's entry path, if it is on disk.
    fn installed_path() -> Result<String> {
        let dir = std::env::current_dir().map_err(|error| error.to_string())?;
        Ok(dir
            .join("node_modules")
            .join(PACKAGE)
            .join(BIN)
            .to_string_lossy()
            .into_owned())
    }

    /// The server from npm, updated when a newer release exists; the installed copy if the check fails.
    fn npm_server(&mut self, id: &LanguageServerId) -> Result<String> {
        if let Some(path) = &self.installed {
            return Ok(path.clone());
        }
        zed::set_language_server_installation_status(
            id,
            &zed::LanguageServerInstallationStatus::CheckingForUpdate,
        );
        let installed = zed::npm_package_installed_version(PACKAGE)?;
        let result = match zed::npm_package_latest_version(PACKAGE) {
            Ok(latest) if installed.as_deref() != Some(latest.as_str()) => {
                zed::set_language_server_installation_status(
                    id,
                    &zed::LanguageServerInstallationStatus::Downloading,
                );
                zed::npm_install_package(PACKAGE, &latest)
            }
            Ok(_) => Ok(()),
            // Offline: keep what is installed, if anything.
            Err(_) if installed.is_some() => Ok(()),
            Err(error) => Err(error),
        };
        if let Err(error) = result {
            let message = format!("couldn't install {PACKAGE}: {error}");
            zed::set_language_server_installation_status(
                id,
                &zed::LanguageServerInstallationStatus::Failed(message.clone()),
            );
            return Err(message);
        }
        zed::set_language_server_installation_status(
            id,
            &zed::LanguageServerInstallationStatus::None,
        );
        let path = Self::installed_path()?;
        self.installed = Some(path.clone());
        Ok(path)
    }
}

/// `settings.rxc.path` and `settings.typescript.tsdk`, from the user's `lsp.rx-language-server.settings`.
fn setting(settings: &LspSettings, section: &str, key: &str) -> Option<String> {
    settings
        .settings
        .as_ref()?
        .get(section)?
        .get(key)?
        .as_str()
        .filter(|value| !value.is_empty())
        .map(str::to_string)
}

/// Overlays `over` onto `base`, objects key by key.
fn merge(base: &mut Value, over: Value) {
    match (base, over) {
        (Value::Object(base), Value::Object(over)) => {
            for (key, value) in over {
                merge(base.entry(key).or_insert(Value::Null), value);
            }
        }
        (base, over) => *base = over,
    }
}

impl zed::Extension for RxExtension {
    fn new() -> Self {
        RxExtension { installed: None }
    }

    fn language_server_command(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let settings = LspSettings::for_worktree(SERVER_ID, worktree).unwrap_or_default();
        let (path, mut args) = match settings.binary.as_ref().and_then(|b| b.path.clone()) {
            Some(path) => (
                path,
                settings
                    .binary
                    .as_ref()
                    .and_then(|b| b.arguments.clone())
                    .unwrap_or_default(),
            ),
            None => (self.npm_server(id)?, Vec::new()),
        };
        if !args.iter().any(|arg| arg == "--stdio") {
            args.push("--stdio".to_string());
        }
        let env = setting(&settings, "rxc", "path")
            .map(|rxc| vec![("RXC".to_string(), rxc)])
            .unwrap_or_default();
        let is_script = [".js", ".mjs", ".cjs"]
            .iter()
            .any(|ext| path.ends_with(ext));
        if is_script {
            args.insert(0, path);
            Ok(zed::Command {
                command: zed::node_binary_path()?,
                args,
                env,
            })
        } else {
            Ok(zed::Command {
                command: path,
                args,
                env,
            })
        }
    }

    fn language_server_initialization_options(
        &mut self,
        _id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<Value>> {
        let settings = LspSettings::for_worktree(SERVER_ID, worktree).unwrap_or_default();
        let tsdk = setting(&settings, "typescript", "tsdk").or_else(|| {
            worktree
                .read_text_file("node_modules/typescript/package.json")
                .ok()
                .map(|_| format!("{}/node_modules/typescript/lib", worktree.root_path()))
        });
        let mut options = match tsdk {
            Some(tsdk) => json!({ "typescript": { "tsdk": tsdk } }),
            None => json!({}),
        };
        if let Some(user) = settings.initialization_options {
            merge(&mut options, user);
        }
        let empty = options.as_object().is_some_and(|o| o.is_empty());
        Ok((!empty).then_some(options))
    }

    fn language_server_workspace_configuration(
        &mut self,
        _id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<Value>> {
        Ok(LspSettings::for_worktree(SERVER_ID, worktree)
            .ok()
            .and_then(|settings| settings.settings))
    }
}

zed::register_extension!(RxExtension);
