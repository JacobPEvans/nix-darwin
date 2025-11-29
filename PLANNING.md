# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Repository Context

- **Purpose**: Declarative macOS system management for M4 Max MacBook Pro (128GB RAM)
- **Target**: Production-ready nix-darwin configuration with home-manager
- **Approach**: Clean slate, minimal initial setup, incremental enhancement
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix 2.31.2

## Near-Term Goals (Next 1-2 Months)

### 1. Profile Development

**Goal**: Implement multiple system profiles for different use cases

**Profiles to Create**:

1. **work**: Professional development environment
   - Communication apps (Slack, Zoom)
   - Productivity tools
   - Lighter weight than dev profile

2. **dev**: Full development environment
   - Language runtimes (Python, Go, Rust)
   - Development tools and IDEs
   - Database clients
   - Container tools (Docker, Colima)

3. **ai-research**: Machine learning and AI development
   - Ollama and model management
   - Python ML libraries
   - Jupyter and data science tools
   - Separate APFS volume for models (optional)

4. **minimal**: Bare essentials only
   - Shell tools only
   - For clean environment testing
   - Quick switching for troubleshooting

**Implementation**:
```nix
darwinConfigurations = {
  default = ...;
  work = ...;
  dev = ...;
  ai-research = ...;
  minimal = ...;
};
```

**Switching Profiles**:
```bash
darwin-rebuild switch --flake ~/.config/nix#work
darwin-rebuild switch --flake ~/.config/nix#dev
```

### 2. Essential Application Installation

**Goal**: Install and configure essential applications via Nix

**Applications to Research**:
- Obsidian - Knowledge management
- Raycast - Productivity launcher
- Brave - Web browser
- Slack - Team communication

**Approach**:
1. Search for nix package availability
2. Add to appropriate profile (some may be profile-specific)
3. Configure declaratively where possible

### 3. macOS System Preferences

**Goal**: Declaratively manage macOS system settings

**Priority Settings**:
- Dock preferences (size, auto-hide, position)
- Finder settings (show hidden files, default view)
- Trackpad and mouse settings
- Keyboard shortcuts

**Implementation Example**:
```nix
system.defaults = {
  dock = {
    autohide = true;
    tilesize = 48;
  };
  finder = {
    AppleShowAllExtensions = true;
  };
  NSGlobalDomain = {
    AppleKeyboardUIMode = 3;
  };
};
```

## Long-Term Vision (6-12 Months)

### 1. Multi-Machine Synchronization

**Goal**: Share configuration across multiple machines with machine-specific overrides

**Structure**:
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

- **Automated Backups**: Time Machine integration
- **Custom Services**: LaunchAgents for personal scripts
- **Development Reproducibility**: Per-project Nix shells with direnv

### 3. Pure Nix System

**Goal**: Completely declarative system with no imperative package management

**Status**: Foundation complete - all packages now via nix
**Next Steps**: Maintain discipline of always adding packages to config

## Success Criteria

### Short-Term (Next 1-2 Months)
- ⬜ At least 2 profiles implemented (default + work or dev)
- ⬜ Essential GUI applications installed via Nix
- ⬜ Basic macOS system preferences configured
- ⬜ Profile switching tested and documented

### Long-Term (6-12 Months)
- ⬜ All planned profiles implemented and tested
- ⬜ Multi-machine configuration support (if applicable)
- ⬜ Automated backup and recovery procedures
- ⬜ Pure Nix system maintained (no imperative installs)

## Known Limitations

### Non-Blocking Issues

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix
   - Impact: None (warnings can be ignored)
   - Resolution: Will resolve when Nix version catches up

2. **Single Profile**: Only default profile exists
   - Impact: Cannot test profile switching yet
   - Resolution: Implement additional profiles (planned)

3. **GPG Warning Persists**: "unsafe ownership" warning still appears
   - Impact: None (GPG fully functional, keys work)
   - Resolution: May be false positive, not blocking functionality

4. **Empty Homebrew**: Homebrew configured but no packages
   - Impact: None (intended state - nix-first approach)
   - Status: Working as designed

## Maintenance Plan

### Weekly
- Review and update PLANNING.md with new tasks
- Commit any configuration tweaks
- Test system updates: `darwin-rebuild switch`

### Monthly
- Update flake dependencies: `nix flake update`
- Review and test new package versions
- Move completed work from PLANNING.md to CHANGELOG.md
- Garbage collect old generations: `nix-collect-garbage -d`

### Quarterly
- Audit installed packages for unused items
- Review and optimize configuration
- Update documentation for accuracy
- Consider new features and enhancements

## Resources

See [README.md](README.md) for documentation links and references.
