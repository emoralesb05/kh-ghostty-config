# KH Ghostty Config

A Kingdom Hearts–themed terminal configuration for [Ghostty](https://ghostty.org/),
with two color variants matched to [kh-vscode-theme](https://github.com/emoralesb05/kh-vscode-theme),
custom world-themed shaders, a one-shot variant switcher, and a fish title hook
that names your terminal after a KH world.

![Ghostty](https://img.shields.io/badge/Terminal-Ghostty-1a1a1a?style=for-the-badge)
![Theme](https://img.shields.io/badge/Theme-Kingdom%20Hearts-purple?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## What's inside

- **Two themes** — `kh-gold` (warm, near-black, gold cursor) and `kh-silver`
  (cool blue-black, cyan cursor). Palettes are aligned 1:1 with the matching
  KH VS Code variants so your editor and terminal share an identity.
- **Four custom shaders** — `dive-to-heart`, `destiny-islands`, `twilight-town`,
  `world-that-never-was`. All preserve text legibility via terminal-luminance
  masking and are tuned for use with `background-opacity` around 0.82.
- **`kh-variant` CLI** — `gold | silver | toggle | status`. Swaps Ghostty,
  VS Code, Cursor, and the `KH_VARIANT` fish universal var in one shot.
- **Fish title hook** — sets the terminal title to `<World> · <basename(pwd)>`,
  using [kh-fish-theme](https://github.com/emoralesb05/kh-fish-theme)'s world
  detection if present, or falling back to a small inline detector.

## Prerequisites

**Required:**

- **macOS** — `kh-variant` uses macOS-specific paths for VS Code and Cursor settings. Linux/Windows aren't supported yet (PRs welcome).
- [**Ghostty**](https://ghostty.org/) — any recent version with `custom-shader` and `themes/` directory support.
- **Python 3** — used by `kh-variant`. Already present on macOS by default.

**Optional companions** — install whichever you want; the installer doesn't require any of them:

| Tool | What you get without it |
|------|-------------------------|
| [Fish shell](https://fishshell.com/) | The title hook (`fish/kh_ghostty_world_title.fish`) only runs in fish. Other shells just won't see it. |
| [VS Code](https://code.visualstudio.com/) | `kh-variant` skips the VS Code update with a friendly message. |
| [Cursor](https://cursor.sh/) | `kh-variant` skips the Cursor update with a friendly message. |
| [kh-vscode-theme](https://github.com/emoralesb05/kh-vscode-theme) | Without it installed, `kh-variant gold/silver` will set `workbench.colorTheme` to `"KH Gold (Subtle)"` — VS Code/Cursor will warn that the theme is missing. **Install this if you plan to use `kh-variant`.** |
| [kh-fish-theme](https://github.com/emoralesb05/kh-fish-theme) | The fish title hook falls back to its own (less rich) inline world detector instead of using `__fish_kh_detect_world`. |

## Install

One-liner (curl):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/emoralesb05/kh-ghostty-config/main/install.sh)
```

Or clone and install:

```bash
git clone https://github.com/emoralesb05/kh-ghostty-config.git
cd kh-ghostty-config
bash install.sh
```

What it does:

- Symlinks `themes/*` → `~/.config/ghostty/themes/`
- Symlinks `shaders/*.glsl` → `~/.config/ghostty/shaders/`
- Backs up any in-the-way files first (`*.bak.<timestamp>`)
- Installs `bin/kh-variant` → `~/.local/bin/kh-variant`
- Installs `fish/kh_ghostty_world_title.fish` → `~/.config/fish/conf.d/`
- Does **not** create or modify `~/.config/ghostty/config`

In remote (curl-pipe) mode the installer first downloads sources into
`~/.local/share/kh-ghostty-config/` and then symlinks from there, so the
"symlinks, not copies" invariant holds in both modes.

## After install

Add (or merge) the following into `~/.config/ghostty/config`:

```ini
theme = kh-gold
font-family = JetBrainsMono Nerd Font
font-size = 14
background-opacity = 0.82
background-blur = 30
custom-shader = ~/.config/ghostty/shaders/dive-to-heart.glsl

# Splits & quick-terminal (suggested)
keybind = cmd+d=new_split:right
keybind = cmd+shift+d=new_split:down
keybind = cmd+[=goto_split:previous
keybind = cmd+]=goto_split:next
keybind = cmd+shift+enter=toggle_split_zoom
keybind = global:cmd+grave_accent=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-animation-duration = 0.18

# Fish as login shell
command = /opt/homebrew/bin/fish --login
```

Reload Ghostty with `cmd+shift+,`.

## Switching variants

```bash
kh-variant gold      # → KH Gold (warm)
kh-variant silver    # → KH Silver (cool)
kh-variant toggle    # → flip whichever is active
kh-variant status    # → which is active right now
```

`kh-variant` keeps four things in sync:

| Surface | What it does |
|---------|--------------|
| Ghostty | Rewrites the `theme = kh-…` line in `~/.config/ghostty/config` |
| VS Code | Sets `workbench.colorTheme` to `KH Gold (Subtle)` / `KH Silver (Subtle)` |
| Cursor | Same as VS Code, on the Cursor settings file |
| Fish | `set -Ux KH_VARIANT gold|silver` so kh-fish-theme can react |

Then it reminds you to press `cmd+shift+,` to reload Ghostty.

## Themes

| Variant | Background | Foreground | Cursor |
|---------|-----------|-----------|--------|
| `kh-gold` | `#09070F` (warm near-black) | `#F7F1E2` | `#F3C76E` (gold) |
| `kh-silver` | `#0C1018` (cool blue-black) | `#F4F8FF` | `#C9EEFF` (cyan) |

## Shaders

All shaders use the same compositing pattern: additive overlay, with a
luminance mask so effects sit behind text rather than on top of it.

| Shader | Mood | Suggested for |
|--------|------|---------------|
| `dive-to-heart.glsl` | Drifting starfield + heart-of-light bloom | Default; long sessions |
| `destiny-islands.glsl` | Warm sunset, palm-frond silhouettes | Quiet/note-taking |
| `twilight-town.glsl` | Sepia drift, light streaks, clock-tower vignette | Reading/docs |
| `world-that-never-was.glsl` | Black, occasional neon-pink rain | Late night / focus |

Switch shader by editing the `custom-shader = …` line in `~/.config/ghostty/config`.

## Customization

The themes and shaders here are the canonical source. `~/.config/ghostty/`
contains symlinks back to this repo after install, so you can tweak in place
and see the effect live (after a Ghostty reload).

If you change the palette, also update the matching VS Code variant in
[kh-vscode-theme](https://github.com/emoralesb05/kh-vscode-theme) so the two
stay aligned.

## Uninstall

```bash
bash uninstall.sh
```

Removes the symlinks, restores the most recent backups (if any), and removes
`kh-variant` and the fish conf.d hook.

## Related

- [kh-fish-theme](https://github.com/emoralesb05/kh-fish-theme) — Fish prompt with HP/MP, world detection, Command Menu
- [kh-vscode-theme](https://github.com/emoralesb05/kh-vscode-theme) — Matching VS Code / Cursor color themes
- [claude-keyblade-statusbar](https://github.com/emoralesb05/claude-keyblade-statusbar) — Claude Code statusline
- [peon-ping-kh-pack](https://github.com/emoralesb05/peon-ping-kh-pack) — KH voice pack

## License

MIT — Ed Morales

---

**May your heart be your guiding key.**
