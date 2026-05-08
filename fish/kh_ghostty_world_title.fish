# kh_ghostty_world_title.fish
#
# Sets the terminal window title to "<World> · <basename(pwd)>" on every prompt,
# using kh-fish-theme's world detection if present, or a small inline fallback.
#
# Emits OSC 0 (icon + window title) and OSC 2 (window title only) so terminals
# that distinguish the two render correctly. Both are wrapped in \e]…\e\\
# (string terminator) so tmux and other multiplexers can pass them through.
#
# Disable with: set -gx KH_GHOSTTY_TITLE_DISABLE 1

# Skip non-interactive shells (e.g. scripts, ssh-forwarded commands).
status is-interactive; or exit 0

# --- Fallback world detector (used if kh-fish-theme isn't installed) ---
function __kh_ghostty_fallback_world
    if test -f Dockerfile -a \( -d terraform -o -d k8s -o -d .github/workflows \)
        echo 'Space Paranoids'; return
    end
    if test -f pnpm-workspace.yaml -o -f lerna.json -o -f nx.json -o -f rush.json
        echo 'The World That Never Was'; return
    end
    if test -f package.json
        if command grep -q '"react"' package.json 2>/dev/null
            echo 'Traverse Town'; return
        end
        echo 'Twilight Town'; return
    end
    if test -f go.mod -o -f Cargo.toml -o -f requirements.txt -o -f pyproject.toml
        echo 'Hollow Bastion'; return
    end
    if test -d docs
        echo 'Radiant Garden'; return
    end
    echo 'Destiny Islands'
end

function __kh_ghostty_world
    if functions -q __fish_kh_detect_world
        __fish_kh_detect_world
    else
        __kh_ghostty_fallback_world
    end
end

function __kh_ghostty_set_title --on-event fish_prompt
    if test -n "$KH_GHOSTTY_TITLE_DISABLE"
        return
    end

    set -l world (__kh_ghostty_world)
    set -l dir (basename -- "$PWD")
    set -l title "$world · $dir"

    # OSC 0 (icon + window title) and OSC 2 (window title) — ST-terminated for tmux pass-through.
    printf '\e]0;%s\e\\' "$title"
    printf '\e]2;%s\e\\' "$title"
end
