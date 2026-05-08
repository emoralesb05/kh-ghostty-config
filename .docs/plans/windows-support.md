# Windows support

Currently `kh-variant` works on macOS (native) and Linux/WSL (via XDG paths).
Windows is unsupported because the editor settings paths and fish-on-Windows
considerations weren't worth working out for 0.1.0.

## Scope

`bin/kh-variant` is the only piece that's platform-specific. `kh-shader`,
the install scripts, and the shaders/themes are all path-portable already.

## Editor settings paths on Windows

| Editor | Path |
|--------|------|
| VS Code | `%APPDATA%\Code\User\settings.json` |
| Cursor | `%APPDATA%\Cursor\User\settings.json` |
| VS Code extensions | `%USERPROFILE%\.vscode\extensions\` |
| Cursor extensions | `%USERPROFILE%\.cursor\extensions\` |

`%APPDATA%` is typically `C:\Users\<user>\AppData\Roaming`. Python's `Path.home()`
gives `%USERPROFILE%`, so we can build the APPDATA path as
`Path(os.environ["APPDATA"])` or fall back to `~/AppData/Roaming`.

## Implementation outline

In `_editor_paths()` in `bin/kh-variant`:

```python
if sys.platform == "win32":
    appdata = Path(os.environ.get("APPDATA", HOME / "AppData" / "Roaming"))
    vscode_settings = appdata / "Code" / "User" / "settings.json"
    cursor_settings = appdata / "Cursor" / "User" / "settings.json"
elif sys.platform == "darwin":
    # ...existing macOS branch
elif:
    # ...existing Linux/WSL branch
```

And the fish universal var:

- On Windows, fish is unusual (typically WSL or Cygwin). If `shutil.which("fish")`
  finds it, use it as on Linux. If not, just skip with a friendly message.

## Ghostty on Windows

Ghostty itself ships for macOS and Linux as of 1.3.x. Native Windows isn't
supported. So the Ghostty config part of `kh-variant` is moot on Windows
unless the user has Ghostty under WSL. In that case the `~/.config/ghostty/config`
path works as on Linux.

This means: a "Windows" version of `kh-variant` is really for **VS Code/Cursor
sync only** — the user wouldn't have Ghostty natively to switch theme on.
That's still useful as half-functionality.

## Acceptance criteria

- `kh-variant gold` on Windows updates VS Code + Cursor settings.
- Skips Ghostty config gracefully if not present (already handled).
- Skips fish var gracefully if fish not found (already handled).
- `kh-variant status` works (reads what's configured).
- Documented in README under Prerequisites.

## Pre-work

1. Test the existing `kh-variant` script on Windows under WSL — likely already
   works since it'd hit the Linux branch. Confirm.
2. For native Windows (no WSL), implement the `win32` branch.
3. Test in a Windows VM or via someone with a Windows machine.

## Risks / open questions

- Path separator handling: Python's `Path` handles `/` vs `\` automatically,
  so should be fine.
- File encoding: VS Code on Windows sometimes saves settings as UTF-16 with
  BOM. Our regex-replace might need to detect encoding. Worth testing.
- Permissions: `%APPDATA%` is per-user, no admin needed. Good.
- Line endings: VS Code/Cursor settings files use LF on Mac/Linux, sometimes
  CRLF on Windows. Our regex doesn't care, but be careful not to convert.

## Priority

Low. This is a "would be nice" feature. Most of the target audience is on
macOS or Linux (where Ghostty is supported). Windows support would be more
about VS Code/Cursor parity than Ghostty, and that's covered better by
[kh-vscode-theme](https://github.com/emoralesb05/kh-vscode-theme) directly.
