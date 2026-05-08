# Fish title hook (revisit)

Set the Ghostty window title to `<World> · <basename(pwd)>` on every prompt,
where `<World>` comes from kh-fish-theme's `__fish_kh_detect_world`.

## What we already learned (0.1.0 attempt)

- **OSC 0/2 work fine in Ghostty 1.3.x** — but only with `\a` (BEL) terminator.
  The `\e\\` (ST) terminator is silently rejected.
- **Our fish_prompt handler does fire** — confirmed via `functions --handlers`.
  Manual call with BEL terminator successfully changes the titlebar.
- **Title gets overwritten every prompt** — even with `shell-integration-features`
  set to `cursor,sudo` (no `title`), Ghostty reverts the title to PWD on every
  prompt cycle. Strongly suggests Ghostty derives the window title from OSC 7
  (working directory) internally, *outside* of the fish handler chain.
- **`functions __ghostty_mark_prompt_start` returned "doesn't exist"** in one
  test — but the handler list showed it registered. Either an investigation
  artifact (different tab/session), or Ghostty registers handlers via a
  mechanism that doesn't appear in `functions -a`.

## Approach options for 0.2.0

### A. Find Ghostty's auto-title-from-CWD config flag

Most likely the cleanest fix exists somewhere in Ghostty's options. Worth
checking:
- Ghostty's source: search for OSC 7 handling and where it touches window title
- Ghostty's docs/release notes for `window-title`, `title-from-cwd`, etc.
- Ghostty Discord/issues for prior reports

If a flag exists, our job is just: set it, then keep our existing fish hook
with the BEL fix.

### B. Wrap Ghostty's prompt-start function

Override `__ghostty_mark_prompt_start` so it calls Ghostty's original logic
*and then* emits our OSC 2 last:

```fish
if functions -q __ghostty_mark_prompt_start
    functions -c __ghostty_mark_prompt_start __kh_orig_mark_prompt_start
    functions -e __ghostty_mark_prompt_start
    function __ghostty_mark_prompt_start --on-event fish_prompt
        __kh_orig_mark_prompt_start
        set -l world (__fish_kh_detect_world)
        set -l dir (basename -- "$PWD")
        printf '\e]2;%s\a' "$world · $dir"
    end
end
```

**Risk**: brittle. Tied to Ghostty's internal function name.

### C. Use `tab-title` config option directly

Ghostty has both window title and tab title concepts. Tab titles may follow
different rules. If we can bind tab title → our string via a config option,
we sidestep the OSC chain entirely.

## Acceptance criteria

- Window or tab title shows `<World> · <basename>` after every prompt.
- Survives `cd`-ing between directories (title updates accordingly).
- Survives running a command (title may briefly show the command, but reverts
  to `<World> · <basename>` after the command completes).
- Doesn't break Ghostty's other shell-integration features (cursor, sudo).
- Works in tmux pass-through (`\a` BEL terminator already handles this).

## Pre-work

1. Reproduce the behavior on a fresh Ghostty install to rule out user-config
   noise.
2. Read Ghostty's source for OSC handling and window-title state.
3. Survey Ghostty's config docs for any title-related options I missed.

## Out of scope

- Restoring the title to a specific format on uninstall (Ghostty reverts to
  default automatically when the hook is removed).
- Tab title vs. window title distinction unless it's the only viable path.
