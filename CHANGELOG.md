# Changelog

All notable changes to this nix-darwin configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) using YYYY-MM-DD format.

## 2025-11-21

### Added

- **Complete Package Management via Nix**: Successfully transitioned all package management to nix/nix-darwin with homebrew as fallback only.
  - Added claude-code 2.0.44 from nixpkgs (system package)
  - Added gemini-cli 0.15.3 from nixpkgs (system package)
  - Added gnupg 2.4.8 from nixpkgs (system package)
  - Added nodejs 24.11.1 (nodejs_latest) from nixpkgs (system package)
  - Added VS Code 1.106.0 via home-manager declarative configuration
- **AI Agent Instructions**: Enhanced CLAUDE.md with comprehensive guidance for handling duplicate packages and PATH prioritization issues.

### Changed

- **VS Code Configuration**: Updated from deprecated `programs.vscode.userSettings` to `programs.vscode.profiles.default.userSettings` in home.nix to resolve home-manager deprecation warning.
- **Package Management Philosophy**: Enforced nixpkgs-first approach with comprehensive documentation of why packages "disappear" when installed outside nix.

### Fixed

- **Duplicate Package Management**: Resolved conflicts between homebrew and nix-managed packages by removing all homebrew duplicates:
  - Uninstalled homebrew: gemini-cli, gnupg, node (and 18 dependency packages)
  - Uninstalled homebrew cask: claude-code 2.0.49
  - System now uses exclusively nix-managed versions
- **PATH Priority Issues**: Fixed PATH prioritization where `/opt/homebrew/bin` took precedence over `/run/current-system/sw/bin`, causing old homebrew versions to be found before nix versions.
- **GPG Directory Permissions**: Fixed ownership and permissions on `~/.gnupg` directory (700 for directories, 600 for files) to resolve "unsafe ownership" warnings.
- **home.nix File Loss**: Recovered from accidental file truncation by restoring from backup file (home.nix~) created during darwin-rebuild.

### Verified

- All packages now resolve to nix store paths:
  - claude: `/run/current-system/sw/bin/claude` (v2.0.44)
  - gemini: `/run/current-system/sw/bin/gemini` (v0.15.3)
  - gpg: `/run/current-system/sw/bin/gpg` (v2.4.8)
  - node: `/run/current-system/sw/bin/node` (v24.11.1)
  - code: `/etc/profiles/per-user/jevans/bin/code` (v1.106.0)
- GPG keys preserved and functional after transition from homebrew to nix
- VS Code launches successfully with declarative settings management

### Documentation

- Updated CLAUDE.md with package management best practices
- Streamlined README.md to focus on quick reference (removed setup duplication)
- Enhanced SETUP.md with comprehensive troubleshooting for duplicate packages and PATH issues
- Updated PLANNING.md to reflect completed work and current system state

## 2025-11-20

### Added

- **GitHub CLI (gh)**: Added gh package to system configuration for PR management and GitHub workflow automation following ai-assistant-instructions best practices.
- **Project Documentation**: Created comprehensive README.md with quick start guide, architecture overview, and system management instructions.
- **Change Tracking**: Established CHANGELOG.md following Keep a Changelog format with calendar versioning.
- **Project Planning**: Created PLANNING.md with detailed roadmap, current status, and step-by-step action items.

### Changed

- **System Packages**: Expanded from minimal git/vim to include gh CLI for enhanced development workflow.

## 2025-11-19

### Added

- **Initial Nix Darwin Setup**: Created minimal nix-darwin configuration for M4 Max MacBook Pro with flake-based architecture.
- **Home Manager Integration**: Integrated home-manager for declarative user environment management.
- **Zsh Configuration Migration**: Migrated complete ~/.zshrc configuration to home-manager declarative format including:
  - Shell aliases (ll, llt, lls, tgz, python, pip)
  - Custom functions (gitmd for branch merge and delete)
  - Session logging to ~/logs/ with timestamp
  - Automatic .DS_Store cleanup for ~/.config/, ~/git/, ~/obsidian/
  - Tab width configuration (2 spaces)
- **Comprehensive Documentation**: Created SETUP.md with detailed setup guide, issues solved, troubleshooting, and lessons learned.

### Fixed

- **Determinate Nix Compatibility**: Disabled nix-darwin's Nix management (`nix.enable = false`) to resolve conflict with Determinate Nix installer.
- **Documentation Build Warnings**: Disabled documentation generation (`documentation.enable = false`) to suppress builtins.toFile warnings and speed up builds.
- **Home Manager File Conflicts**: Added `backupFileExtension = "backup"` to automatically backup existing files (e.g., .zshrc.backup).
- **System File Conflicts**: Manually renamed /etc/bashrc to /etc/bashrc.before-nix-darwin to allow nix-darwin activation.
- **Deprecated API Usage**: Changed `programs.zsh.initExtra` to `programs.zsh.initContent` to resolve deprecation warning.
- **Git Permission Issues**: Resolved git object ownership issues that prevented flake updates.

### Changed

- **Configuration Structure**: Moved old Linux-based configuration to backup/ directory (git-ignored).
- **Branching Strategy**: Created feature/minimal-darwin-setup branch for initial development following conventional git workflow.

## Configuration Decisions

### Why These Choices Were Made

1. **Determinate Nix Over Official Installer**:
   - Better macOS integration with proper APFS volume management
   - Optimized for Apple Silicon
   - Enhanced security features
   - Forward-compatible settings (eval-cores, lazy-trees)

2. **Minimal Initial Setup**:
   - Faster iteration and testing
   - Easier to understand and debug
   - Foundation for future expansion
   - Clean slate approach rather than adapting Linux config

3. **Documentation Disabled**:
   - Warnings were from upstream nix-darwin/home-manager
   - No functionality impact
   - Significantly faster build times
   - Can be re-enabled if needed

4. **Single Default Profile**:
   - Test and validate core functionality first
   - Architecture supports multiple profiles (work, dev, ai-research, minimal)
   - Profile switching planned for future enhancement

5. **Flake-Based Configuration**:
   - Reproducible builds with locked dependencies
   - Better dependency management
   - Industry best practice
   - Required for modern Nix workflows

## Known Limitations

1. **Nix Settings Warnings**: Harmless warnings about `eval-cores` and `lazy-trees` from Determinate Nix forward-compatible settings. Current Nix version (2.31.2) ignores unknown settings gracefully.

2. **Single Profile**: Only default profile implemented. Additional profiles (work, dev, ai-research, minimal) require manual creation.

3. **Homebrew Coexistence**: Homebrew remains installed independently. Future work will integrate via nix-darwin's Homebrew module.

4. **Minimal macOS Preferences**: No system preferences configured yet. Will expand in future iterations.

## Migration Notes

### What Changed for Users

**Before**:
- Traditional dotfiles (.zshrc in home directory)
- Manual system configuration
- Imperative package management

**After**:
- Declarative configuration via Nix
- Version-controlled system state
- Reproducible environment
- Atomic updates with rollback capability

**User Experience**:
- Shell behaves identically (all aliases and functions preserved)
- Original .zshrc backed up to .zshrc.backup
- System updates via `darwin-rebuild switch`
- New capabilities: profile switching, declarative packages

## Rollback Procedure

If issues occur, rollback is straightforward:

```bash
# 1. Restore original .zshrc
mv ~/.zshrc.backup ~/.zshrc

# 2. Restore system files
sudo mv /etc/bashrc.before-nix-darwin /etc/bashrc

# 3. Uninstall nix-darwin
sudo /nix/store/*/darwin-uninstaller

# 4. System returns to pre-nix-darwin state
```

## Dependencies

**Runtime**:
- Nix 2.31.2+ (Determinate Nix installer)
- macOS on Apple Silicon (aarch64-darwin)
- Git (for flake operations)

**Build**:
- nix-darwin 25.05 (fetched via flake)
- home-manager 25.05 (fetched via flake)
- nixpkgs unstable (fetched via flake)
