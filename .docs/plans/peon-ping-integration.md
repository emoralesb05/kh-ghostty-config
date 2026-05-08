# Peon-ping integration

Trigger KH-themed audio cues from `kh-variant` and `kh-shader` actions —
e.g. play a "key acquired" SFX when switching variants, a "world traversal"
SFX when switching shaders. The user has [peon-ping](https://github.com/emoralesb05/peon-ping)
installed with the [KH voice pack](https://github.com/emoralesb05/peon-ping-kh-pack),
so the audio is already on disk.

## What we already learned (0.1.0 attempt)

- The public `peon` CLI doesn't have a "play one specific sound" command.
  Closest is `peon preview <category>` which plays *all* sounds in a category
  in sequence — too long for a CLI side-effect.
- Peon-ping is hooked into Claude Code session events via `~/.claude/hooks/peon-ping`,
  not designed as a general-purpose SFX trigger.
- Direct `afplay` on a sound file in `peon-ping-kh-pack/` would work but
  bypasses peon-ping's mute/volume settings, which is rude UX.

## Approach options for 0.2.0

### A. Upstream a `peon play <category> [--single]` command

Open a PR / issue against peon-ping for a single-shot trigger that:
- Picks one random sound from the category
- Respects the user's mute/volume/pack-rotation settings
- Returns immediately (non-blocking)

Then wire `kh-variant` / `kh-shader` to call `peon play <category> --single`
after a successful action.

This is the right answer in terms of "use the API." Cost: depends on
turnaround on the upstream PR.

### B. Read peon-ping's config + play directly via afplay

Read `~/.claude/hooks/peon-ping/config.json` (or wherever it lives) to:
- Check if the user has muted (skip if so)
- Get current pack
- Pick a random sound file from the category
- Play it via `afplay <sound> &` (non-blocking)

Pros: works without upstream changes.
Cons: re-implements peon-ping's logic in two places — drift risk.

### C. Peon-ping libexec helper

Peon-ping's libexec dir (`/opt/homebrew/Cellar/peon-ping-1.7.0/libexec`)
might contain a script we can call directly that handles single-sound playback
internally. Worth inspecting — could give us option A without an upstream PR.

## Suggested category mapping

| Action | Peon-ping category | Why |
|--------|-------------------|-----|
| `kh-variant gold/silver` | `task.complete` | "Choice made" feel |
| `kh-variant toggle` | `task.acknowledge` | Quick ack |
| `kh-shader set <name>` | `task.acknowledge` | Quick ack |
| `kh-shader auto` | `task.complete` | "World detected" feel |
| `install.sh` complete | `session.start` | Welcome cue |
| `uninstall.sh` complete | `task.complete` | Closure cue |

## Acceptance criteria

- `kh-variant silver` + peon-ping installed → plays one short sound, returns
  prompt immediately.
- Peon-ping muted → no sound, no error message.
- Peon-ping not installed → no sound, no error, `kh-variant` works normally.
- No double-play (the hook fires exactly once per action).

## Pre-work

1. Inspect `/opt/homebrew/Cellar/peon-ping-*/libexec/` for a single-sound
   helper (option C).
2. If none, draft an upstream PR proposal for option A.
3. Decide whether to proxy via peon-ping or fall back to `afplay` if both
   options A and C are blocked.

## Risks

- Audio cue can become annoying. Provide a `KH_GHOSTTY_QUIET=1` env var or
  config flag to disable, similar to `KH_GHOSTTY_TITLE_DISABLE` in the title-hook
  plan.
- Cross-platform: peon-ping is macOS-only currently. Linux support waits on
  peon-ping itself.
