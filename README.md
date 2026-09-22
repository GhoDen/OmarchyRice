# OmarchyRice - Beautiful, fun & mine

My personal system-configuration repo for [Omarchy](https://omarchy.org) that layers
declarative package management on top of Omarchy's own tooling. The goal isn't
Nix's usual "perfect reproducibility" pitch — it's a single source of truth you
can glance at to know exactly what's installed, edit to change it, and trust
that a stale entry doesn't quietly linger on the system after you remove it.

## Philosophy

- **One file describes what's installed.** `home/packages.txt` is the entire
  package manifest — pacman, AUR, Nix, and Nix-flake-sourced apps, all in one
  place, split into sections.
- **Delete a line, and it's gone from the machine too.** Every section is
  self-pruning: remove a package from the file, rerun the install script (or
  `home-manager switch`), and it's uninstalled — not just skipped on future
  runs.
- **Manual installs stay manual.** Anything installed outside this repo (GPU
  drivers, one-off tools, per-device stuff other machines don't need) is never
  touched by the pruning logic, because it was never tracked in the first
  place. See [How pruning actually works](#how-pruning-actually-works).

## Repo layout

```
.
├── home/
│   ├── flake.nix       # Nix flake inputs (nixpkgs, home-manager, and any
│   │                   #   GitHub-sourced apps like superfile, markshot)
│   ├── home.nix        # home-manager config; reads packages.txt at eval time
│   └── packages.txt    # THE manifest — see below
├── dotfiles/            # Configurations linked into ~/.config by Home Manager
└── scripts/
    ├── install.sh      # Full setup and synchronization
    ├── switch.sh       # Only re-applies the Home Manager flake
    ├── clean.sh        # nix-collect-garbage -d
    ├── modules/        # Package, web-app, Nix, keyd, Yazi, and VM setup steps
    └── keyd/           # Installs and enables the tracked keyd configuration
```

## `home/packages.txt` — the manifest

```ini
# vim: ft=dosini

[pacman]
fish

[aur]

[nix]
git
kitty
mesa-demos
fastfetch

[nix-flake]
superfile
```

The manifest currently supports seven sections, each with a different purpose:

| Section       | What goes here                                                 | Installed via                                            |
|---------------|----------------------------------------------------------------|----------------------------------------------------------|
| `[pacman]`    | Official Arch repo packages                                    | `omarchy-pkg-add` / `omarchy-pkg-drop`                   |
| `[aur]`       | AUR packages                                                   | `omarchy-pkg-aur-add` / `omarchy-pkg-drop`               |
| `[remove]`    | Packages that must not be installed on this machine            | `omarchy-pkg-drop`                                       |
| `[webapps]`   | Omarchy web apps, one per line as `name url icon-url`          | `omarchy-webapp-install`                                |
| `[webapps-remove]` | Web apps that must not be installed on this machine       | `omarchy-webapp-remove`                                  |
| `[nix]`       | Any package that exists in nixpkgs                             | `home.packages`, resolved by name against `pkgs`         |
| `[nix-flake]` | Apps only available as a GitHub flake (not in nixpkgs)         | `home.packages`, resolved against `flake.nix`'s `inputs` |

Comments (`#`) and blank lines are ignored everywhere. Neovim will syntax-highlight
this as INI (`dosini`) thanks to the modeline on line 1.

**Adding a `[nix-flake]` entry is a two-step process**, and always will be —
this is a real Nix constraint, not a limitation of this repo. Flake inputs
have to be declared statically in `flake.nix` *before* anything can be
evaluated, so:

1. Add the source to `flake.nix`:
   ```nix
   inputs.some-new-app = {
     url = "github:owner/repo";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
2. Add the name to `[nix-flake]` in `packages.txt` to actually turn it on.

Removing it from `[nix-flake]` alone is enough to uninstall it — you don't
need to touch `flake.nix` unless you're dropping the source entirely.

Use `[remove]` for Omarchy defaults that should not be present on this machine:

```ini
[remove]
gnome-calculator
satty
```

These entries are an explicit removal list, not ownership state. They are
dropped on every `./scripts/install.sh` run if installed, including packages
that Omarchy installed before this repository was set up. A package cannot
appear in both `[remove]` and `[pacman]` or `[aur]`; the install script stops
before changing packages if it finds such an overlap. Removal uses `pacman -Rns`,
so packages required by other installed packages are left in place and warned
about.

Web apps use three whitespace-separated fields: a display name, the URL to
open, and an icon URL. For example:

```ini
[webapps]
Reddit https://reddit.com/ https://example.com/reddit-icon.png
```

Web apps installed by this repository are tracked in
`.state/webapps-managed.txt`. Removing an entry from `[webapps]` removes it on
the next install, while entries in `[webapps-remove]` are removed on every
install regardless of whether this repository installed them. Names and URLs
must not contain unquoted whitespace.

## Usage

**First run on a new machine** (assumes Omarchy is already installed):

```bash
git clone <this-repo>
cd omarchyrice
./scripts/install.sh
```

This will:
1. Sync `[pacman]` and `[aur]` packages (installs anything missing, drops
   anything no longer listed that this repo previously installed, and applies
   the explicit `[remove]` list).
2. Install and prune the configured web apps.
3. Install Nix if it isn't already present, then update every flake input to
   its latest revision.
4. Run Home Manager, which installs everything under `[nix]` and
   `[nix-flake]` and links the tracked dotfiles.
5. Enable keyd using `dotfiles/keyd/default.conf`, install the Omarchy Yazi
   theme integration, and enable libvirt's default network.

The install script is system-mutating. It requires an Omarchy installation,
uses `sudo` for keyd and libvirt setup, may add the current user to the
`libvirt` group, and may require logging in again before the new group takes
effect. The script also updates flake inputs on every run, so the exact Nix
versions are intentionally not fixed by the repository.

**Every time after** — add or remove a line in `packages.txt`, commit, push,
and on any machine running this repo:

```bash
git pull --rebase
./scripts/install.sh
```

Same script, same result, whether you're adding something new or pruning
something old.

**Reclaiming disk space** from old Nix generations:

```bash
./scripts/clean.sh
```

**Apply only Home Manager changes** when package and system synchronization is
not needed:

```bash
./scripts/switch.sh
```

`switch.sh` selects `homeConfigurations.<your-username>` using `whoami`. The
current flake defines only the `denver` configuration, so the username must
match `denver` unless `home/flake.nix` is changed.

## How pruning actually works

The tricky part of self-pruning package management: naively diffing
"installed packages" against "what's in the file" would also try to uninstall
things you installed manually and never wanted this repo to manage — GPU
drivers being the obvious example.

The fix is a small local state file per package type
(`.state/pacman-managed.txt`, `.state/aur-managed.txt`, and
`.state/webapps-managed.txt`), tracking **only what this repo has installed on
this machine**, not everything installed. Every run:

1. Read the current desired list from `packages.txt`.
2. Read the *previous* desired list from `.state/`.
3. Install anything newly desired.
4. Drop anything that was in the previous state but isn't desired anymore.
5. Overwrite the relevant `.state/` file with the current managed list.

Anything never added through this repo never enters `.state/`, so it's
structurally invisible to step 4 — there's no special-case code protecting
manual installs, they're just outside the diff entirely.

`[nix]` and `[nix-flake]` don't need any of this machinery — Home Manager's
generation model already uninstalls anything removed from `home.packages`
when you rerun `switch.sh`. That's the one part of this setup that's
declarative out of the box.

`.state/` is machine-specific and `.gitignore`d — it should never be
committed or copied between machines.

## Known caveats

- **Username is currently hardcoded** in `flake.nix` (`user = "denver"`).
  `switch.sh` resolves the flake attribute via `whoami`, so this only works
  cleanly on a machine where your actual username matches. Worth making
  dynamic before cloning onto a machine with a different username.
- **`[nix]` and `[nix-flake]` only resolve top-level `pkgs.<name>` attributes.**
  Nested packages (e.g. `python3Packages.requests`) aren't handled by the
  current parser.
- **`home/flake.lock` is intentionally ignored.** `install.sh` regenerates and
  updates it locally, so it is not a portable record of the exact inputs used
  on another machine.
