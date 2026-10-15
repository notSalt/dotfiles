# dotfiles
my dotfiles

## YASB + GlazeWM on two machines

The work laptop and the personal PC share the same widgets, styles and
GlazeWM config, but each keeps its own bar layout. YASB and GlazeWM read their
config straight from this repo, so a `git pull` updates them.

| File | Scope | What's in it |
|---|---|---|
| `yasb/base.yaml` | shared | top-level settings |
| `yasb/widgets.yaml` | shared | widget definitions |
| `yasb/styles.css` | shared | styles |
| `yasb/machine.example.yaml` | template | bars and machine-only widgets (the `home` label) |
| `yasb/machine.yaml` | per machine, git-ignored | your copy of the example, tweaked for this PC |
| `glazewm/*` | shared | GlazeWM config and the per-monitor workspace AHK script |

YASB only reads a single `config.yaml`, so `build.ps1` joins
`base.yaml` + `machine.yaml` + `widgets.yaml` into `yasb/config.yaml`
(git-ignored). `yasb_colors.css` is also git-ignored, since YASB regenerates it
from each machine's Windows accent colour.

### First-time setup (once per machine)

1. Clone the repo and close YASB and GlazeWM.
2. Run the setup script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1
   ```
   It points `~/.config/yasb` and `~/.glzr/glazewm` at the repo with directory
   junctions (no admin needed; existing folders are renamed to
   `*.backup-<timestamp>`), turns on the git hooks, and creates
   `yasb/machine.yaml` from the example.
3. Tweak `yasb/machine.yaml` for this PC. The comments at the top list what to
   change on the laptop.
4. Run `.\build.ps1`, then start YASB and GlazeWM.

### Day to day

- **`git pull`**: the post-merge hook rebuilds `config.yaml` and YASB reloads
  by itself. Press `alt+shift+r` to reload GlazeWM. If `glazewm-ws.ahk`
  changed, restart GlazeWM so it relaunches the script.
- **Changed `machine.yaml`**: run `.\build.ps1`.
- **Changed a shared piece**: commit it, then pull on the other machine.

Edit the pieces, not `yasb/config.yaml`, which is overwritten on every build.

### Machine-only widgets

Add them under `widgets:` at the bottom of `machine.yaml` (indented two spaces,
like `home`). A widget can't be in both `machine.yaml` and `widgets.yaml`,
since YAML doesn't allow the same key twice.
