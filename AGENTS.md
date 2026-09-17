# Repository Instructions

## What This Repo Is

- This is a personal Omarchy desktop configuration, not an application with a build or test suite.
- `home/packages.txt` is the package source of truth. Its sections map to install mechanisms: `[pacman]` and `[aur]` use Omarchy package commands; `[nix]` resolves top-level attributes from nixpkgs; `[nix-flake]` resolves flake inputs declared in `home/flake.nix`.
- Home Manager reads `home/packages.txt` at Nix evaluation time, and `home/home.nix` maps the tracked dotfiles into `~/.config/`.

## Package Changes

- Adding a `[nix-flake]` package requires both a matching input in `home/flake.nix` and the package name in `home/packages.txt`; the input must expose `packages.<system>.default`.
- The Nix package resolver only supports top-level `pkgs.<name>` attributes. Do not add nested nixpkgs paths to `[nix]` without changing the resolver.
- `.state/` contains machine-local pacman/AUR ownership state used for pruning. Never commit or copy it between machines; removal from the manifest can uninstall packages previously tracked there.
- `home/flake.lock` is intentionally ignored and is regenerated locally by the install workflow.

## Commands And Hazards

- Full setup or synchronization: `./scripts/install.sh`. It requires an Omarchy installation, may install Nix, updates flake inputs to latest on every run, synchronizes/prunes pacman and AUR packages, and activates Home Manager. Treat it as a system-mutating command, not a test.
- Apply only the Home Manager configuration: `./scripts/switch.sh`. It selects the configuration using `whoami`; `home/flake.nix` currently defines only the hardcoded `denver` configuration, so another username will fail until the flake is changed.
- Reclaim old Nix generations: `./scripts/clean.sh` (`nix-collect-garbage -d`).
- There is no configured test, lint, formatter, or CI workflow. For non-system-mutating checks, run `bash -n scripts/*.sh` and `nix flake show ./home --extra-experimental-features "nix-command flakes"` when Nix is available.
