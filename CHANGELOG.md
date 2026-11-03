# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## Unreleased

## 1.1.0 - 2026-11-03

### Added

- nvm-style subcommands: `use`, `install`, `uninstall`, `list`, `list-remote` and `help` work with
  or without leading dashes (e.g. `goenv use 1.24.2`).
- `major.minor` shorthand for `--use`: `goenv use 1.24` activates the newest installed `1.24.x`.
- `major.minor` shorthand for `--install`: `goenv install 1.24` installs the newest stable `1.24.x`
  release (pre-releases are skipped).
- Tab completions (`completions/goenv.fish`) for subcommands, installed versions (`use` /
  `uninstall`) and remote releases (`install`).
- `fisher remove` now removes the Go SDK path the plugin added to `fish_user_paths`.

### Changed

- Internal functions and variables use the `_bwgoenv_` prefix. The path saved by 1.0.0
  (`__fish_goenv_managed_path`) is migrated automatically.

### Fixed

- `goenv --install 1.24` no longer fails with `gzip: invalid header`; the shorthand used to produce
  a nonexistent download URL.


## 1.0.0 - 2026-08-21

### Added

- `goenv` fish wrapper that runs the real `goenv` binary and, on `--use <ver>` / `-use <ver>` /
  `--use=<ver>`, points fish's `PATH` at the selected Go version via universal `fish_user_paths`.
- Replaces only the SDK path previously added by the plugin, leaving other user paths intact.
- `GOENV_GO_ROOT` variable to override the default `~/.go` install root.
