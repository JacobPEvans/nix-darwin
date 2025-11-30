# References & Documentation

Comprehensive collection of external documentation and resources for this nix configuration.

## Table of Contents

- [Nix Ecosystem](#nix-ecosystem)
- [nix-darwin Options](#nix-darwin-options)
- [home-manager Options](#home-manager-options)
- [macOS System Defaults](#macos-system-defaults)
- [AI CLI Tools](#ai-cli-tools)
- [Editor Configuration](#editor-configuration)
- [Package Search](#package-search)

---

## Nix Ecosystem

### Core Documentation

| Resource | URL | Description |
|----------|-----|-------------|
| Nix Manual | https://nix.dev/manual/nix/stable/ | Official Nix language and CLI reference |
| Nix Pills | https://nixos.org/guides/nix-pills/ | Deep-dive tutorial series for learning Nix |
| Nix Flakes | https://nixos.wiki/wiki/Flakes | Community wiki on flakes |
| Determinate Nix | https://determinate.systems/ | Nix installer and tooling (used in this config) |

### nix-darwin

| Resource | URL | Description |
|----------|-----|-------------|
| nix-darwin GitHub | https://github.com/nix-darwin/nix-darwin | Main repository |
| nix-darwin Manual | https://nix-darwin.github.io/nix-darwin/manual/ | Configuration options reference |
| nix-darwin Options | https://nix-darwin.github.io/nix-darwin/manual/options.html | Searchable options list |

### home-manager

| Resource | URL | Description |
|----------|-----|-------------|
| home-manager GitHub | https://github.com/nix-community/home-manager | Main repository |
| home-manager Manual | https://nix-community.github.io/home-manager/ | User guide |
| home-manager Options | https://nix-community.github.io/home-manager/options.xhtml | Searchable options list |

---

## nix-darwin Options

### Source Files (GitHub Raw)

Direct links to nix-darwin source for understanding option implementations:

| Module | URL |
|--------|-----|
| Dock | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/dock.nix |
| Finder | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/finder.nix |
| NSGlobalDomain | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/NSGlobalDomain.nix |
| Trackpad | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/trackpad.nix |
| Keyboard | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/keyboard.nix |
| Login Window | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/loginwindow.nix |
| Screensaver | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/screensaver.nix |
| Screencapture | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/screencapture.nix |
| Spaces | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/spaces.nix |
| menuExtraClock | https://raw.githubusercontent.com/nix-darwin/nix-darwin/master/modules/system/defaults/menuExtraClock.nix |
| All Defaults | https://github.com/nix-darwin/nix-darwin/tree/master/modules/system/defaults |

### Quick Reference: Dock Options

```nix
system.defaults.dock = {
  # Appearance
  tilesize = 64;                    # Icon size (pixels)
  magnification = true;             # Enlarge on hover
  largesize = 80;                   # Magnified size (16-128)
  orientation = "bottom";           # "bottom", "left", "right"

  # Behavior
  autohide = false;                 # Auto hide/show
  autohide-delay = 0.0;             # Delay before showing (seconds)
  autohide-time-modifier = 0.15;    # Animation speed
  launchanim = true;                # Bounce on launch
  show-process-indicators = true;   # Dot indicators
  show-recents = false;             # Recent apps section
  minimize-to-application = true;   # Minimize into app icon
  mineffect = "scale";              # "genie", "suck", "scale"
  showhidden = true;                # Translucent hidden apps
  static-only = false;              # Only show running apps

  # Spaces
  mru-spaces = false;               # Auto-rearrange spaces
  expose-group-apps = true;         # Group in Mission Control

  # Hot Corners (action values)
  # 1=Disabled, 2=Mission Control, 3=App Windows, 4=Desktop
  # 5=Screen Saver On, 6=Screen Saver Off, 10=Sleep Display
  # 11=Launchpad, 12=Notification Center, 13=Lock Screen, 14=Quick Note
  wvous-tl-corner = 2;              # Top-left
  wvous-tr-corner = 12;             # Top-right
  wvous-bl-corner = 3;              # Bottom-left
  wvous-br-corner = 14;             # Bottom-right
};
```

### Quick Reference: Finder Options

```nix
system.defaults.finder = {
  # Visibility
  AppleShowAllFiles = true;         # Show hidden files
  AppleShowAllExtensions = true;    # Show all extensions
  FXEnableExtensionChangeWarning = false;

  # Window
  ShowStatusBar = true;             # Bottom status bar
  ShowPathbar = true;               # Path breadcrumbs
  _FXShowPosixPathInTitle = true;   # Full path in title
  FXPreferredViewStyle = "Nlsv";    # "icnv", "Nlsv", "clmv", "Flwv"

  # Sorting
  _FXSortFoldersFirst = true;       # Folders on top
  _FXSortFoldersFirstOnDesktop = true;

  # Search
  FXDefaultSearchScope = "SCcf";    # "SCev", "SCcf", "SCsp"

  # New Windows
  NewWindowTarget = "Home";         # "Computer", "OS volume", "Home", etc.

  # Desktop
  CreateDesktop = true;             # Show desktop icons
  ShowExternalHardDrivesOnDesktop = true;
  ShowHardDrivesOnDesktop = false;
  ShowMountedServersOnDesktop = false;
  ShowRemovableMediaOnDesktop = true;

  # Trash
  FXRemoveOldTrashItems = true;     # Auto-remove after 30 days

  # Application
  QuitMenuItem = false;             # Allow Cmd-Q to quit Finder
};
```

---

## macOS System Defaults

### Reading Current Values

```bash
# Read all defaults for a domain
defaults read com.apple.dock
defaults read com.apple.finder
defaults read NSGlobalDomain

# Read specific key
defaults read com.apple.dock tilesize

# Find a setting (when you don't know the domain)
defaults find "keyword"
```

### Common Domains

| Domain | Description |
|--------|-------------|
| `com.apple.dock` | Dock settings |
| `com.apple.finder` | Finder settings |
| `NSGlobalDomain` | Global system preferences |
| `com.apple.AppleMultitouchTrackpad` | Trackpad settings |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | Bluetooth trackpad |
| `com.apple.desktopservices` | Desktop services (.DS_Store behavior) |
| `com.apple.screencapture` | Screenshot settings |
| `com.apple.screensaver` | Screensaver settings |
| `com.apple.loginwindow` | Login window settings |
| `com.apple.spaces` | Mission Control/Spaces |
| `com.apple.controlcenter` | Control Center settings |

### Useful Commands

```bash
# List all domains
defaults domains | tr ',' '\n'

# Export all settings for a domain
defaults export com.apple.dock -

# Monitor changes in real-time (useful for finding settings)
# Terminal 1:
defaults read com.apple.dock > /tmp/before.plist
# Make change in System Settings
# Terminal 1:
defaults read com.apple.dock > /tmp/after.plist
diff /tmp/before.plist /tmp/after.plist
```

### External macOS Defaults Resources

| Resource | URL | Description |
|----------|-----|-------------|
| macos-defaults.com | https://macos-defaults.com/ | Visual guide to macOS defaults |
| defaults-write.com | https://www.defaults-write.com/ | Collection of hidden defaults |
| mathiasbynens/dotfiles | https://github.com/mathiasbynens/dotfiles/blob/main/.macos | Famous macOS defaults script |

---

## AI CLI Tools

### Claude Code

| Resource | URL | Description |
|----------|-----|-------------|
| GitHub Issues | https://github.com/anthropics/claude-code/issues | Bug reports and feedback |
| npm Package | https://www.npmjs.com/package/@anthropic-ai/claude-code | Package info |

### Gemini CLI

| Resource | URL | Description |
|----------|-----|-------------|
| Configuration Guide | https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html | Settings documentation |
| GitHub | https://github.com/google-gemini/gemini-cli | Main repository |

### GitHub Copilot CLI

| Resource | URL | Description |
|----------|-----|-------------|
| VS Code Docs | https://code.visualstudio.com/docs/copilot/overview | Copilot overview |
| CLI Reference | https://docs.github.com/en/copilot/github-copilot-in-the-cli | CLI documentation |

---

## Editor Configuration

### VS Code

| Resource | URL | Description |
|----------|-----|-------------|
| Settings Reference | https://code.visualstudio.com/docs/getstarted/settings | All settings |
| Copilot Settings | https://code.visualstudio.com/docs/copilot/reference/copilot-settings | Copilot-specific settings |
| Keyboard Shortcuts | https://code.visualstudio.com/docs/getstarted/keybindings | Keybindings reference |

### Neovim (if applicable)

| Resource | URL | Description |
|----------|-----|-------------|
| nixvim | https://github.com/nix-community/nixvim | Neovim configuration in Nix |
| Neovim Docs | https://neovim.io/doc/ | Official documentation |

---

## Package Search

| Resource | URL | Description |
|----------|-----|-------------|
| NixOS Packages | https://search.nixos.org/packages | Search nixpkgs |
| NixOS Options | https://search.nixos.org/options | Search NixOS options |
| Homebrew Formulae | https://formulae.brew.sh/ | Search Homebrew packages |
| Homebrew Casks | https://formulae.brew.sh/cask/ | Search Homebrew GUI apps |

---

## This Configuration

| File | Purpose |
|------|---------|
| [README.md](README.md) | Project overview and quick start |
| [SETUP.md](SETUP.md) | Initial setup and configuration decisions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [CLAUDE.md](CLAUDE.md) | AI agent instructions (not for humans) |
| [CHANGELOG.md](CHANGELOG.md) | History of changes |
| [PLANNING.md](PLANNING.md) | Future work and roadmap |

---

## Contributing New References

When adding new external links:

1. Add them to this file in the appropriate section
2. Include a brief description
3. Prefer official documentation over third-party
4. Test that links are not broken

Last updated: 2025-11-29
