# fish-goenv

A [fish](https://fishshell.com/) plugin that makes [`goenv`](https://github.com/ankitcharolia/goenv)
(the Golang Version Manager) actually work in fish.

`goenv --use <ver>` only writes a `PATH` export to `~/.bashrc`, which fish never
sources — so `go` stays missing in fish. This plugin wraps `goenv` with a fish
function that transparently runs the real binary and, on `--use`, repoints your
fish `PATH` to the selected version. Because it updates a **universal** variable,
the change applies to every fish session — including ones already open.

## Requirements

- [fish](https://fishshell.com/) 3.2+
- [ankitcharolia/goenv](https://github.com/ankitcharolia/goenv) on your `PATH`

## Install

With [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install bulkware/fish-goenv
```

## Usage

Use `goenv` exactly as before — the wrapper is transparent:

```fish
goenv --install 1.21.6   # installs to ~/.go/1.21.6
goenv --use 1.21.6       # fish PATH switches; `go version` reflects it
go version               # go version go1.21.6 ...
```

Any version you install lands under the goenv root (`~/.go` by default), so the
plugin can activate it — no manual `fish_add_path` needed.

## Configuration

By default the plugin looks for versions under `~/.go/<ver>/bin`. Override the
root if your goenv installs elsewhere:

```fish
set -Ux GOENV_GO_ROOT /custom/go/root
```

## How it works

- Wraps `goenv` with a fish function (`functions/goenv.fish`).
- Passes all arguments to the real `goenv` binary via `command goenv`.
- Parses `--use <ver>` / `-use <ver>` / `--use=<ver>` and updates
  `fish_user_paths` (universal scope), replacing only the SDK path previously
  added by this plugin.

## License

GPL-3.0 — see [LICENSE](LICENSE).
