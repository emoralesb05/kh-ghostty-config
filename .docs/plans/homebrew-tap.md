# Homebrew tap

Mirror the [`claude-keyblade-statusbar`](https://github.com/emoralesb05/claude-keyblade-statusbar)
distribution model: a Homebrew tap that lets users run `brew install
emoralesb05/tap/kh-ghostty-config` and get the symlinks set up automatically.

## Motivation

Lower the install friction. Right now the install path is:

```bash
git clone https://github.com/emoralesb05/kh-ghostty-config.git
cd kh-ghostty-config
bash install.sh
```

…or the curl one-liner. With a tap, it's just:

```bash
brew install emoralesb05/tap/kh-ghostty-config
kh-ghostty-setup
```

Discoverability is also better — `brew search kh` would surface it.

## Approach

### Tap repository

Create or extend `emoralesb05/homebrew-tap` (or whatever the existing tap
name is — claude-keyblade-statusbar already lives in one). Add a Formula:

```ruby
# Formula/kh-ghostty-config.rb
class KhGhosttyConfig < Formula
  desc "Kingdom Hearts-themed Ghostty terminal config"
  homepage "https://github.com/emoralesb05/kh-ghostty-config"
  url "https://github.com/emoralesb05/kh-ghostty-config/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "fish" => :optional
  depends_on "python@3"

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/kh-variant"
    bin.install_symlink libexec/"bin/kh-shader"
  end

  def caveats
    <<~EOS
      Run `kh-ghostty-setup` to symlink themes and shaders into ~/.config/ghostty/.
      See README at #{homepage} for usage.
    EOS
  end

  test do
    system "#{bin}/kh-variant", "status"
  end
end
```

### Wrapper script

Add a `kh-ghostty-setup` shell script that does the install.sh equivalent
but using `libexec` paths (since brew installs read-only). Or just have
`install.sh` run from libexec — simpler.

### Versioning

Each tagged release becomes a new formula version. Use Homebrew's standard
versioning. The `url` field would be updated in the formula on each release.

## Acceptance criteria

- `brew install emoralesb05/tap/kh-ghostty-config` succeeds on a clean Mac
- After install, `kh-variant`, `kh-shader` are on PATH
- Running `kh-ghostty-setup` (or whatever name) symlinks shaders + themes
- `brew uninstall kh-ghostty-config` removes the binaries cleanly (and
  invokes our uninstall.sh to remove symlinks)
- Formula passes `brew audit --strict`
- Tap-style install path documented in README

## Pre-work

1. Tag a stable release (`v0.1.0`) with a release tarball
2. Compute SHA256 of the release tarball
3. Decide where the tap lives — extend an existing tap or create new
4. Adapt `install.sh` to work from a libexec source root (read-only)

## Risks

- Maintaining the tap formula on every release adds toil. Could automate
  with a GitHub Actions workflow that opens a PR to the tap on each release.
- Symlinks into `~/.config/` aren't standard Homebrew behavior. Some
  reviewers may push back on the formula. Mitigation: do the symlinks in
  the `kh-ghostty-setup` post-install script, not in `install do`, so the
  formula install itself is just "drop binaries on PATH."
