# dotfiles
my dotfiles

## YASB + GlazeWM on two machines

The work laptop and the personal PC share the same widgets, styles and
GlazeWM config, but each keeps its own bar layout.

YASB only reads a single `config.yaml`, so `sync.ps1` builds it from pieces:

| File | Scope | What's in it |
|---|---|---|
| `yasb/base.yaml` | shared | top-level settings |
| `yasb/bars.laptop.yaml` / `yasb/bars.pc.yaml` | per machine | bar screens, placement and widget order |
| `yasb/widgets.yaml` | shared | every widget definition except `home` |
| `yasb/widgets.laptop.yaml` / `yasb/widgets.pc.yaml` | per machine | widgets whose settings differ (the `home` label) |
| `yasb/styles.css` | shared | copied as-is |
| `glazewm/*` | shared | copied as-is |

`yasb/config.yaml` and `yasb/yasb_colors.css` are generated on each machine and
are git-ignored. YASB regenerates `yasb_colors.css` from the Windows accent colour.

### First-time setup (once per machine)

```powershell
setx DOTFILES_MACHINE laptop   # or: pc
```

Reopen the terminal so the variable is picked up.

### Applying changes

```powershell
git pull
.\sync.ps1
```

YASB reloads by itself. Press `alt+shift+r` to reload GlazeWM. If
`glazewm-ws.ahk` changed, restart GlazeWM so it relaunches the script.

Always edit the pieces in this repo, not the generated
`~/.config/yasb/config.yaml`, which is overwritten on every sync.

### Adding a machine-specific widget

Add it to `widgets.laptop.yaml` and `widgets.pc.yaml` (indented two spaces,
like `home`). It must not also be defined in `widgets.yaml`, since YAML doesn't
allow the same key twice.
