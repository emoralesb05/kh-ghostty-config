# Auto-shader on cd

When you `cd` into a different project, the world detection changes (e.g.,
from "Destiny Islands" to "Twilight Town"). It'd be a satisfying KH detail
to have the **shader automatically swap** to match the new world.

`kh-shader auto` already does this on demand. This plan: make it run automatically.

## Approach

A fish hook in `conf.d/` that calls `kh-shader auto` whenever `$PWD` changes
*and* the detected world has changed:

```fish
# conf.d/kh_ghostty_world_shader.fish
status is-interactive; or exit 0

function __kh_auto_shader --on-variable PWD
    if test -n "$KH_GHOSTTY_AUTO_SHADER_DISABLE"
        return
    end
    set -l world (__fish_kh_detect_world)
    if test "$world" = "$__kh_last_world"
        return
    end
    set -g __kh_last_world $world
    kh-shader auto >/dev/null 2>&1 &
end
```

## Caveats

### 1. Reload requirement

Ghostty doesn't pick up shader changes without `cmd+shift+,`. So the user
would need to manually reload after each cd. That defeats the magic.

**Possible fix**: investigate whether Ghostty has a CLI like `ghostty +reload`
or accepts a SIGHUP/USR1 to reload config. If yes, the hook could trigger it.

If reloading still requires the keystroke, this feature is mostly useless
unless we also solve auto-reload.

### 2. Performance

Calling `kh-shader auto` per `cd` is non-trivial: it spawns Python, reads
the Ghostty config, rewrites it, calls fish for world detection. On a hot
loop of `cd ../../foo`, that's a few hundred ms of overhead per directory.

**Mitigation**: cache the last-detected world (already in the hook above),
only fire `kh-shader auto` when world *changes*. This makes most `cd`s a
no-op.

### 3. Conflicts with `kh-shader set` user override

If the user explicitly ran `kh-shader set destiny-islands`, our auto-hook
shouldn't override it on the next cd. Need a "manual override" flag:
- Set when user calls `kh-shader set` directly
- Cleared when user calls `kh-shader auto` directly
- Auto-hook respects it (skips changes if set)

This is more state to manage. Could live as a fish universal var
(`KH_SHADER_MANUAL_OVERRIDE`).

## Acceptance criteria

- Cd into a Rust project → shader switches to Hollow Bastion's shader
  (assuming such a shader exists by then)
- Cd back to a generic dir → shader switches to dive-to-heart
- No spam / re-runs when cd-ing within the same world
- Reloads Ghostty automatically OR prompts user once per session
- Honors manual `kh-shader set` overrides
- Disable-able via `KH_GHOSTTY_AUTO_SHADER_DISABLE=1`

## Pre-work

1. Resolve the auto-reload question (Ghostty CLI or signal). Without it,
   this feature is friction-y.
2. Decide on the manual-override semantics.
3. Profile `kh-shader auto` end-to-end — see if we can skip the Python
   startup cost (e.g., inline the world→shader logic in the fish hook).

## Risks

- **Annoying flicker** when cd-ing rapidly across world types
- **Lost work**: if `kh-shader set` accidentally rewrites a config the user
  manually edited, they'd be frustrated. The sticky `.kh-shader-orig` backup
  exists but isn't robust against many sequential overwrites.
- **Cross-shell**: only works for fish users. `cd` hooks in zsh/bash would
  need separate scripts.
