# Future plans

Living index of work that's *not* in 0.1.0 but is on the table for later
versions. Each plan is a self-contained pitch — motivation, approach, risks,
acceptance criteria — not a binding commitment.

## Carried over from 0.1.0 (cut intentionally)

| Plan | Why it was cut | Suggested target |
|------|----------------|------------------|
| [fish-title-hook.md](./fish-title-hook.md) | Couldn't get reliable behavior — Ghostty 1.3.x rewrites the title from OSC 7 (CWD) on every prompt regardless of fish handler order. Needed a proper investigation of Ghostty's title pipeline that wasn't worth the iteration cost mid-session. | 0.2.0 |
| [peon-ping-integration.md](./peon-ping-integration.md) | The public `peon` CLI doesn't expose a clean per-sound trigger; only `peon preview <category>` which plays the whole pack. Wiring it would need either an upstream API addition to peon-ping or going around it via direct `afplay`. | 0.2.0 |
| [windows-support.md](./windows-support.md) | `kh-variant` macOS-only paths. Linux added during 0.1.0; Windows skipped. | 0.3.0 (low priority) |

## New ideas worth documenting

| Plan | Status |
|------|--------|
| [more-world-shaders.md](./more-world-shaders.md) — shaders for Hollow Bastion, Traverse Town, Radiant Garden, Space Paranoids | brainstormed |
| [auto-shader-on-cd.md](./auto-shader-on-cd.md) — `kh-shader auto` triggered on every directory change (fish hook) | brainstormed |
| [homebrew-tap.md](./homebrew-tap.md) — `brew install emoralesb05/tap/kh-ghostty-config` (matches keyblade-statusbar pattern) | brainstormed |

## Other ideas not yet written up

- **Screenshots in README** — one PNG per shader, gold variant. Needs you to actually capture them.
- **CHANGELOG.md** — once we have multiple tagged releases worth documenting.
- **Accessibility variants** — high-contrast or colorblind-safe versions of the themes (mirror kh-fish-theme's `KH_A11Y` pattern).
- **kh-config CLI** — read and validate `~/.config/ghostty/config`, warn about common misconfigurations (e.g., `macos-option-as-alt = true` breaks the kh-fish-theme Command Menu).
- **Shader hot-reload watcher** — a background daemon that watches `shaders/*.glsl` and triggers Ghostty config reload when a file changes. Would make iterating on shaders dramatically faster.
- **Per-shader configuration** — let users tune shader parameters (rain density, sun position, etc.) via a config file rather than editing GLSL.
- **Variants for KH3 vs KH1 aesthetic** — the KH1 sky in Destiny Islands looks different from KH3's. Could ship both color schemes.
- **Tighter Claude Code statusbar integration** — `kh-variant` could ping `claude-keyblade-statusbar`'s config to keep the Keyblade name in sync (e.g., gold variant → Ultima Weapon). Likely needs an API or shared config.
- **Test suite** — `bats` or `expect` tests for `kh-variant` and `kh-shader` (regex behavior, fallback paths, missing-extension warning, idempotent re-runs).

## How to use this folder

If you decide to act on any of these, treat the markdown file as a starting
brief and write the actual implementation in a feature branch. Update the
plan file as you discover constraints — these aren't sealed; they're notes.

When a plan ships, move its file to `.docs/plans/done/` (or just delete it
and document the result in `CHANGELOG.md`).
