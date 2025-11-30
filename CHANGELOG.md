# Changelog

All notable changes to this nix-darwin configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) using YYYY-MM-DD format.

## 2025-11-30

### Added

- **Hosts + Modules Architecture**: Major refactoring to support multi-host configurations
  - Created `hosts/` directory with host-specific configurations:
    - `macbook-m4/` - Active M4 Max MacBook Pro (nix-darwin + home-manager)
    - `ubuntu-server/` - Template for Ubuntu server (home-manager standalone)
    - `proxmox/` - Template for Proxmox server (home-manager standalone)
    - `windows-server/` - Placeholder for future native Windows Nix support
  - Created `modules/` directory with reusable modules:
    - `darwin/common.nix` - macOS system packages, homebrew, settings
    - `linux/common.nix` - Linux home-manager settings (XDG, packages)
    - `home-manager/` - Cross-platform user configuration (shell, git, vscode, AI CLIs)
  - Created `lib/` directory for shared configuration variables:
    - `user-config.nix` - User info (name, email, GPG key, hostname)
    - `server-config.nix` - Server hostnames and settings
    - `home-manager-defaults.nix` - Shared home-manager settings (DRY)
  - Each non-macOS host has its own `flake.nix` for standalone deployment

- **Modern CLI Tools**: Added productivity tools for humans and AI assistants
  - bat - Better cat with syntax highlighting
  - delta - Better git diff viewer
  - eza - Modern ls replacement with git integration
  - fd - Faster, user-friendly find alternative
  - fzf - Fuzzy finder for interactive selection
  - htop - Interactive process viewer
  - jq - JSON parsing
  - ncdu - NCurses disk usage analyzer
  - tldr - Simplified man pages
  - tree - Directory visualization

- **External Volume Management**:
  - Ollama models symlink to `/Volumes/Ollama/models`
  - `CONTAINER_DATA` environment variable for OrbStack (`/Volumes/ContainerData`)

### Changed

- **DRY Improvements**: Centralized all hardcoded values
  - Username from `userConfig.user.name` everywhere
  - Hostname from `userConfig.host.name`
  - Home-manager settings from `lib/home-manager-defaults.nix`
  - `nixpkgs.config.allowUnfree` moved to `modules/darwin/common.nix`

- **Documentation**: Updated all docs to reflect new structure
  - README.md - New directory structure, hosts table, package categories
  - CLAUDE.md - Updated file paths for permissions and settings
  - PLANNING.md - Simplified, removed completed phases

## 2025-11-29

### Added

- **Phase 2: Application Migration**
  - Added `ripgrep` (v15.1.0) to system packages - fast grep alternative
  - Added `raycast` (v1.103.2) to system packages - productivity launcher (replaces native install)
  - Configured Oh My Zsh via `programs.zsh.oh-my-zsh` with plugins: git, docker, macos, z, colored-man-pages
  - Added zsh enhancements: autosuggestions, syntax highlighting, completion, 100k history

- **Nix-Managed Git Configuration**: Full git configuration via home-manager `programs.git`
  - GPG signing enabled by default (`commit.gpgsign = true`, `tag.gpgSign = true`)
  - Created `home/user-config.nix` for centralized user variables (name, email, GPG key ID)
  - Created `home/git-aliases.nix` with 20 common git aliases (st, lo, lg, co, etc.)
  - Created `home/shell-aliases.nix` with macOS-specific shell aliases
  - Migrated to new `programs.git.settings` syntax (from deprecated `extraConfig`)
  - Comprehensive git settings: histogram diff, rerere, fetch pruning, rebase on pull

- **Sudo Requirements Documentation**: Added TROUBLESHOOTING.md section documenting:
  - Commands that REQUIRE sudo (darwin-rebuild switch)
  - Commands that should NOT use sudo (nix build, git, brew)
  - Instructions for fixing root-owned files

- **VS Code Nix Migration**: Migrated VS Code from native macOS install to Nix-managed
  - Added `vscode` to `darwin/configuration.nix` system packages
  - Created `home/vscode-settings.nix` with migrated general settings (git, terminal, Python, extensions)
  - VS Code now at `/Applications/Nix Apps/Visual Studio Code.app`
  - Settings properly symlinked to Nix store via Home Manager

- **Claude Code Status Line**: Added custom status line configuration
  - Created `statusline-command.sh` showing directory, git branch, model, and output style
  - Configured in `home/home.nix` via `home.file` declarations

- **Shell Aliases**: Added darwin-rebuild convenience alias
  - `d-r` alias for `sudo darwin-rebuild switch --flake ~/.config/nix#default`

### Changed

- **PR Review Fixes**:
  - Renamed git alias `ll` to `lo` to avoid conflict with shell `ll` alias
  - Updated `ss` alias from deprecated `stash save` to modern `stash push` (Git 2.16+)
  - Removed redundant `home` attribute from `user-config.nix` (use `config.home.homeDirectory`)

- **Permission Accuracy Improvements**:
  - Split `fileCommands` into `fileReadCommands` (read-only) + `fileCreationCommands` (mkdir, touch)
  - Fixed comment claiming "read-only" while containing file creation commands
  - Applied same fix to both `claude-permissions.nix` and `gemini-permissions.nix`

- **Gemini CLI sed/awk Permissions**:
  - Moved `sed` and `awk` from excludeTools to coreTools (allow general text processing)
  - Added `sed -i` and `sed --in-place` to excludeTools (block only destructive variants)
  - Created new `textProcessingCommands` category in coreTools

- **VS Code Copilot Settings**: Updated model selection comment from "February 2025+" to "Introduced February 2025" for clarity

### Documentation

- Reduced D-R-Y violations across documentation files
- Updated file organization in CLAUDE.md to include `vscode-settings.nix`
- Simplified README.md by referencing CLAUDE.md for detailed information
- Removed duplicate directory structure and resource sections

## 2025-11-22

### Added

- **Declarative Claude Code Permission Management**: Implemented layered configuration strategy for Claude Code auto-approved commands.
  - Created `home/claude-permissions.nix` with 285 safe auto-approved commands in 24 categories
  - Created `home/claude-permissions-ask.nix` with 32 potentially dangerous commands requiring user approval
  - Nix manages baseline permissions in `~/.claude/settings.json` (version controlled, reproducible)
  - `~/.claude/settings.local.json` remains writable for interactive approvals
  - Three-tier permission strategy: allow (auto-approved), ask (user confirmation), deny (permanently blocked)
  - 40 explicitly DENIED catastrophic operations

### Changed

- **Security Hardening (after comprehensive PR #2 code review)**:
  - **Allow list (285 commands)**: Only safe, read-only operations with minimal risk
  - **Ask list (32 commands)**: Potentially dangerous but legitimate use cases requiring user approval
    - System scripting: osascript (arbitrary AppleScript control)
    - System info: system_profiler, defaults read (information disclosure)
    - File operations: chmod, rm, rmdir, cp, mv, sed, awk (modification/deletion risks)
    - Container operations: docker exec/run (arbitrary code execution in containers)
    - Kubernetes: kubectl apply/create/delete/set/patch, helm install/upgrade/uninstall
    - Cloud: aws s3 cp/sync/rm, aws ec2 run/terminate, aws lambda invoke, aws cloudformation delete
    - Database: sqlite3, mongosh (arbitrary SQL execution)
    - Package execution: npx (arbitrary package download/execution)
  - **Deny list (40 commands)**: Absolutely catastrophic operations, permanently blocked
    - File destruction: rm -rf / variants, system-level modifications
    - Privilege escalation: sudo su/bash/bash -i
    - Credential theft: sensitive file reads (.env, .ssh, .aws, .gnupg)
    - HTTP write operations: curl POST/PUT/DELETE/PATCH (data exfiltration)
    - Network listeners: nc/ncat/socat (reverse shells)

- **Curl security hardening**: Restricted from generic `-s` flag to explicit GET patterns only
  - Prevents ambiguous commands like `curl -s -X POST` bypassing deny rules
  - Only allows: `curl -s -X GET`, `curl --silent --request GET`, etc.

- **Remove dangerous but commonly used commands from auto-approve**:
  - npx (can execute arbitrary npm packages)
  - sed/awk without restrictions (in-place file editing with -i)
  - cp/mv (file overwrite risks)
  - chmod (permission modification risks)
  - docker rm/rmi (removed, moved to ask - destructive)
  - kubernetes apply/create (removed, moved to ask - cluster modification)
  - aws s3 cp/sync (removed, moved to ask - data write/overwrite)
  - aws lambda invoke (removed, moved to ask - execution of arbitrary functions)
  - sqlite3/mongosh (removed, moved to ask - arbitrary SQL)

- **Code cleanup**:
  - Removed unused `readPermissions` variable (duplicate of coreReadTools)
  - Consolidated rm -rf deny patterns (now covers -rf, -fr variants)
  - Removed redundant patterns, added variants for privilege escalation

### Fixed

- Database command syntax issues (removed malformed sqlite3 patterns)
- Duplicate `Bash(sudo rm:*)` - kept only in deny list (catastrophic)
- Curl patterns too permissive (`curl -s:*` could be followed by -X POST)
- Kubernetes and Helm operations that modify cluster state now require user approval
- AWS operations that can incur costs now require user approval

### Documentation

- Updated PLANNING.md with "Recently Completed" section detailing security hardening
- Added comprehensive comments to both permission files explaining risk levels
- Documented principle of least privilege in baseline configuration
- Clarified three-tier strategy with specific risk classifications
- Added comments explaining why each dangerous command is in ask (not deny) list

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
