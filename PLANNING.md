# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Repository Context

- **Purpose**: Multi-host declarative system management
- **Architecture**: hosts + modules pattern with shared lib/ configs
- **Active Host**: M4 Max MacBook Pro (128GB RAM)
- **Templates**: Ubuntu server, Proxmox server, Windows server (placeholder)
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix

## Current Work: Architecture Migration

**Branch**: `refactor/hosts-modules-architecture`
**PR**: #9 (awaiting review)

### Hosts + Modules Refactoring ✅ COMPLETE
- [x] Reorganize to hosts/ + modules/ + lib/ structure
- [x] Create host-specific directories (macbook-m4, ubuntu-server, proxmox, windows-server)
- [x] Extract shared configs to lib/ (user-config.nix, server-config.nix, home-manager-defaults.nix)
- [x] Create modules/darwin/common.nix for macOS system packages
- [x] Create modules/linux/common.nix for Linux home-manager
- [x] Create modules/home-manager/common.nix for cross-platform user config
- [x] Add modern CLI tools (bat, delta, eza, fd, fzf, htop, jq, ncdu, tldr, tree)
- [x] Add Ollama symlink for external volume (/Volumes/Ollama/models)
- [x] Add CONTAINER_DATA environment variable for OrbStack
- [x] Fix DRY violations (centralized home-manager settings, userConfig usage)
- [x] Update documentation for new structure

### Next: macOS Customization Audit
- [ ] Review all System Preferences changes
- [ ] Audit backup/ directory for missed configs
- [ ] Add customizations to `system.defaults`

### Future: Profile System
- [ ] Implement profile variants (development, work, minimal)
- [ ] Profile-specific package sets
- [ ] Profile switching documentation

---

## Near-Term Goals

### macOS System Preferences
**Goal**: Declaratively manage macOS system settings

```nix
system.defaults = {
  dock = { autohide = true; tilesize = 48; };
  finder = { AppleShowAllExtensions = true; };
  NSGlobalDomain = { AppleKeyboardUIMode = 3; };
};
```

### Essential Applications
- Obsidian - Knowledge management
- Brave - Web browser
- Slack - Team communication

### Profile Variants
Extend current architecture with profile-specific modules:
- **development** - Language runtimes, IDEs, debugging tools
- **work** - Communication apps, VPNs
- **minimal** - Bare essentials for recovery

---

## Long-Term Vision

### Multi-Machine Deployment
Current hosts+modules architecture supports this. Next steps:
- Deploy to ubuntu-server and proxmox hosts
- Test home-manager standalone on Linux
- Document deployment workflow

### Advanced Features
- Time Machine integration
- LaunchAgents for personal scripts
- Per-project Nix shells with direnv

---

## Known Limitations

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix
2. **GPG Warning**: "unsafe ownership" warning (functional, not blocking)
3. **Homebrew Exception**: claude-code via homebrew for rapid updates

## Maintenance Plan

**Weekly**: Commit config tweaks, test darwin-rebuild
**Monthly**: `nix flake update`, garbage collect, review CHANGELOG
**Quarterly**: Audit packages, update documentation

## Resources

See [README.md](README.md) for documentation links.
