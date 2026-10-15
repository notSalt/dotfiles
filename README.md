# dotfiles
my dotfiles

## YASB + GlazeWM

Shared across machines, with a per-machine `machine.yaml` (git-ignored) for bar layout and local window rules. YASB and GlazeWM read straight from this repo.

| File | |
|---|---|
| `yasb/base.yaml`, `yasb/widgets.yaml`, `yasb/styles.css` | shared |
| `glazewm/base.yaml`, `glazewm/glazewm-ws.ahk` | shared |
| `*/machine.example.yaml` | template for `machine.yaml` |

`build.ps1` joins the pieces into each app's `config.yaml` (git-ignored).

### Setup (once per machine)

1. Close YASB and GlazeWM.
2. `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
   - links `~/.config/yasb` and `~/.glzr/glazewm` to this repo (old folders are backed up)
   - enables the git hooks
   - creates `machine.yaml` files from the examples
3. Tweak the `machine.yaml` files, run `.\build.ps1`, then start YASB and GlazeWM.

### Updating

`git pull` rebuilds automatically. YASB reloads by itself; press `alt+shift+r` for GlazeWM.
After editing a `machine.yaml`, run `.\build.ps1`.
