# Project Status & Planning

## Repository Context

- **Purpose**: Declarative macOS system management for M4 Max MacBook Pro (128GB RAM)
- **Target**: Production-ready nix-darwin configuration with home-manager
- **Approach**: Clean slate, minimal initial setup, incremental enhancement
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix 2.31.2

### Key Files

- `flake.nix` - Main entry point defining darwinConfigurations.default
- `flake.lock` - Locked dependency versions for reproducibility
- `darwin/configuration.nix` - System-level macOS settings and packages
- `home/home.nix` - User environment (shell, aliases, dotfiles)
- `SETUP.md` - Comprehensive setup guide and troubleshooting
- `CHANGELOG.md` - Version history and completed changes
- `README.md` - Project overview and quick start guide
- `PLANNING.md` - This file, tracking current status and roadmap

## Current Session Progress

### ✅ Completed

1. **Initial Minimal Nix-Darwin Setup** (2025-11-19):
   - Created flake-based configuration structure
   - Configured nix-darwin for Determinate Nix compatibility
   - Set up basic user and system settings
   - Minimal system packages (git, vim)

2. **Home Manager Integration** (2025-11-19):
   - Integrated home-manager into nix-darwin configuration
   - Migrated complete .zshrc to declarative configuration
   - All aliases, functions, and environment variables preserved
   - Automatic file backup system configured

3. **Issue Resolution** (2025-11-19):
   - Fixed Determinate Nix conflict (nix.enable = false)
   - Resolved documentation build warnings
   - Handled file conflicts with backup strategy
   - Fixed deprecated API usage (initExtra → initContent)
   - Resolved git permission issues

4. **Comprehensive Documentation** (2025-11-19):
   - Created SETUP.md with full setup guide
   - Documented all issues and solutions
   - Included troubleshooting section
   - Added lessons learned

5. **GitHub CLI Integration** (2025-11-20):
   - Added gh package to system configuration
   - Rebuilt and activated system with gh
   - Committed with conventional commit format
   - Pushed to feature/minimal-darwin-setup branch

6. **Project Documentation Standards** (2025-11-20):
   - Created README.md following documentation standards
   - Established CHANGELOG.md with Keep a Changelog format
   - Created PLANNING.md for roadmap tracking
   - All documentation committed and pushed to GitHub

## Immediate Next Steps

### 1. GitHub CLI Authentication

**Status**: Pending user action

**Action Required**:

```bash
# Authenticate GitHub CLI
gh auth login
```

**Steps**:

1. Run gh auth login
2. Select: GitHub.com
3. Select: HTTPS
4. Select: Login with a web browser
5. Copy one-time code
6. Authorize in browser

**Dependencies**: None
**Blocks**: PR review workflow, automated PR management

### 2. Review Pull Request Comments

**Status**: Pending gh authentication

**Action Items**:

1. View pull request status:

   ```bash
   gh pr view --web
   # Or in terminal:
   gh pr view
   ```

2. List all PR comments and review threads:

   ```bash
   gh pr view --comments
   ```

3. Analyze each comment for:
   - Validity of suggestion
   - Impact on current implementation
   - Alignment with ai-assistant-instructions standards

4. Document findings for user approval

**Dependencies**: gh authentication
**Estimated Effort**: Review and categorization - 15-30 minutes

### 3. Implement Approved PR Feedback

**Status**: Pending PR review completion

**Action Items**:

1. For each approved suggestion:
   - Create focused commit addressing specific feedback
   - Follow conventional commit format from ai-assistant-instructions
   - Test changes locally with `darwin-rebuild switch`
   - Verify no regressions in functionality

2. Commit strategy:
   - One commit per logical change
   - Clear conventional commit messages
   - Reference PR comment in commit body if applicable

3. Push changes:

   ```bash
   git push origin feature/minimal-darwin-setup
   ```

**Dependencies**: PR review and user approval
**Estimated Effort**: Variable based on feedback volume

### 4. PR Review and Merge Preparation

**Status**: Pending feedback implementation

**Action Items**:

1. Resolve all PR conversations after implementing fixes:

   ```bash
   # View PR status
   gh pr checks

   # Review remaining conversations
   gh pr view --comments
   ```

2. Ensure all CI/CD checks pass (if configured)

3. Request final review or prepare for merge

4. Merge strategy decision:
   - Squash merge (recommended for clean history)
   - Merge commit (preserves individual commits)
   - Rebase merge (linear history)

**Dependencies**: All PR feedback addressed
**Estimated Effort**: Final review - 10-15 minutes

## Medium-Term Enhancements

### 1. Profile Development

**Goal**: Implement multiple system profiles for different use cases

**Profiles to Create**:

1. **work**: Professional development environment
   - VS Code, productivity tools
   - Communication apps (Slack, Zoom)
   - Lighter weight than dev profile

2. **dev**: Full development environment
   - Language runtimes (Python, Node, Go, Rust)
   - Development tools and IDEs
   - Database clients
   - Container tools (Docker, Colima)

3. **ai-research**: Machine learning and AI development
   - Ollama and model management
   - Python ML libraries (TensorFlow, PyTorch)
   - Jupyter and data science tools
   - Separate APFS volume for models (optional)

4. **minimal**: Bare essentials only
   - Shell tools only
   - For clean environment testing
   - Quick switching for troubleshooting

**Implementation Steps**:

1. Add profile definitions to flake.nix:

   ```nix
   darwinConfigurations = {
     default = ...;
     work = ...;
     dev = ...;
     ai-research = ...;
     minimal = ...;
   };
   ```

2. Create shared configuration module for common settings

3. Test profile switching:

   ```bash
   darwin-rebuild switch --flake ~/.config/nix#work
   darwin-rebuild switch --flake ~/.config/nix#dev
   ```

**Dependencies**: None (foundation already in place)
**Estimated Effort**: 2-4 hours per profile + testing

### 2. Essential Application Installation

**Goal**: Install and configure essential applications via Nix

**Applications to Add**:

- **Obsidian**: Knowledge management
- **Raycast**: Productivity launcher
- **Brave**: Web browser
- **Slack**: Team communication
- **VS Code**: Code editor (with extensions)

**Implementation Approach**:

1. Research Nix package availability for each app

2. Add to appropriate profile configuration:

   ```nix
   environment.systemPackages = with pkgs; [
     obsidian
     raycast
     brave
     slack
     vscode
   ];
   ```

3. Configure VS Code via home-manager:

   ```nix
   programs.vscode = {
     enable = true;
     extensions = [ ... ];
     userSettings = { ... };
   };
   ```

**Dependencies**: Profile development (apps may be profile-specific)
**Estimated Effort**: 1-2 hours + configuration time

### 3. macOS System Preferences

**Goal**: Declaratively manage macOS system settings

**Settings to Configure**:

- Dock preferences (size, auto-hide, position)
- Finder settings (show hidden files, default view)
- Trackpad and mouse settings
- Keyboard shortcuts
- Screen saver and energy settings
- App-specific defaults

**Implementation**:

```nix
system.defaults = {
  dock = {
    autohide = true;
    orientation = "bottom";
    tilesize = 48;
  };

  finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;
  };

  NSGlobalDomain = {
    AppleKeyboardUIMode = 3;
    ApplePressAndHoldEnabled = false;
  };
};
```

**Dependencies**: None
**Estimated Effort**: 2-3 hours for comprehensive settings

### 4. Homebrew Migration to Nix-Darwin Management

**Goal**: Replace imperative Homebrew with declarative nix-darwin Homebrew module

**Current State**:

- Homebrew installed and functional
- Packages managed imperatively
- No conflict with Nix

**Target State**:

```nix
homebrew = {
  enable = true;
  onActivation = {
    cleanup = "zap";
    autoUpdate = true;
    upgrade = true;
  };

  brews = [
    # CLI tools that need Homebrew-specific patches
  ];

  casks = [
    # Apps only available via Homebrew
    # Or apps better installed via Homebrew
  ];

  taps = [
    # Custom Homebrew taps
  ];
};
```

**Migration Steps**:

1. Audit current Homebrew installations:

   ```bash
   brew list --formula > brew-formulas.txt
   brew list --cask > brew-casks.txt
   ```

2. Categorize packages:
   - Available in nixpkgs → migrate to Nix
   - Homebrew-specific → declare in homebrew.brews
   - Mac-specific apps → declare in homebrew.casks
   - Unnecessary → remove

3. Implement declarative Homebrew configuration

4. Test activation and verify all apps work

5. Remove imperative Homebrew packages

**Dependencies**: Profile development (Homebrew packages may be profile-specific)
**Estimated Effort**: 3-4 hours + testing

## Long-Term Vision

### 1. Multi-Machine Synchronization

**Goal**: Share configuration across multiple machines with machine-specific overrides

**Approach**:

- Base configuration shared across all machines
- Machine-specific modules for hardware differences
- Secrets management via sops-nix or agenix
- Git repository as single source of truth

**Implementation Structure**:

```
~/.config/nix/
├── flake.nix
├── machines/
│   ├── macbook-m4-max/
│   │   └── configuration.nix
│   └── macbook-m2-air/
│       └── configuration.nix
├── shared/
│   ├── darwin-base.nix
│   └── home-base.nix
└── profiles/
    ├── work.nix
    ├── dev.nix
    └── minimal.nix
```

### 2. Advanced Features

**Automated Backups**:

- Time Machine integration via nix-darwin
- Automated backup verification
- Backup rotation policies

**Custom Services and Daemons**:

- LaunchAgents for personal scripts
- Background services for automation
- System monitoring and alerts

**Development Environment Reproducibility**:

- Per-project Nix shells
- Direnv integration
- Language version management

### 3. Complete Homebrew Replacement

**Goal**: Pure Nix system with Homebrew completely removed

**Requirements**:

- All applications available via Nix or nix-darwin Homebrew module
- Mac-specific apps handled declaratively
- No imperative package management

**Timeline**: Long-term (6-12 months)

## Success Criteria

### Immediate (Current PR)

- ✅ Minimal nix-darwin setup working
- ✅ Home-manager integrated and functional
- ✅ All shell configuration migrated
- ✅ Comprehensive documentation created
- ✅ GitHub CLI installed and configured
- ⬜ All PR comments reviewed and addressed
- ⬜ PR approved and merged to main

### Short-Term (Next 1-2 Months)

- ⬜ At least 2 profiles implemented (default + work or dev)
- ⬜ Essential applications installed via Nix
- ⬜ Basic macOS system preferences configured
- ⬜ Homebrew managed declaratively via nix-darwin

### Long-Term (6-12 Months)

- ⬜ All planned profiles implemented and tested
- ⬜ Complete Homebrew migration or replacement
- ⬜ Multi-machine configuration support (if applicable)
- ⬜ Automated backup and recovery procedures
- ⬜ Pure Nix system with no imperative package management

## Known Issues and Blockers

### Current Blockers

1. **GitHub CLI Authentication**: Requires user interaction to complete
   - **Impact**: Blocks PR review workflow
   - **Resolution**: User runs `gh auth login`

### Non-Blocking Issues

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix
   - **Impact**: None (warnings can be ignored)
   - **Resolution**: Will resolve when Nix version catches up to Determinate settings

2. **Single Profile Limitation**: Only default profile exists
   - **Impact**: Cannot test profile switching yet
   - **Resolution**: Implement additional profiles (planned)

## Resources and References

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Determinate Nix](https://determinate.systems/nix-installer/)
- [ai-assistant-instructions](https://github.com/JacobPEvans/ai-assistant-instructions) - Development workflow standards
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)

## Maintenance Plan

### Weekly

- Review and update PLANNING.md with progress
- Commit any configuration tweaks
- Test system updates with `darwin-rebuild switch`

### Monthly

- Update flake dependencies: `nix flake update`
- Review and test new package versions
- Update CHANGELOG.md with notable changes
- Garbage collect old generations: `nix-collect-garbage -d`

### Quarterly

- Audit installed packages for unused items
- Review and optimize configuration
- Update documentation for accuracy
- Consider new features and enhancements
