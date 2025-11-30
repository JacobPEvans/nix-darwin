# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Repository Context

- **Purpose**: Multi-host declarative system management
- **Architecture**: hosts + modules pattern with shared lib/ configs
- **Active Host**: M4 Max MacBook Pro (128GB RAM)
- **Templates**: Ubuntu server, Proxmox server, Windows server (placeholder)
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix

## Current Work: macOS System Preferences Audit

**Branch**: `feat/macos-system-audit`
**PR**: #10

### Phase 1: System Services & UI Defaults ✅ COMPLETE
- [x] Enable SSH/Remote Login via `services.openssh.enable`
- [x] Create `modules/darwin/dock.nix` with comprehensive settings
- [x] Create `modules/darwin/finder.nix` with power-user settings
- [x] Create `REFERENCES.md` with external documentation links
- [x] Review backup/ folder for reusable configurations

### Phase 2: Input & System UI ✅ COMPLETE
- [x] Keyboard settings (KeyRepeat, InitialKeyRepeat, AppleKeyboardUIMode)
- [x] Trackpad settings (tap-to-click, gestures, force click)
- [x] NSGlobalDomain settings (appearance, text, windows)
- [x] Menu bar clock configuration
- [x] Login window settings
- [x] Screensaver & lock screen (password required immediately)
- [x] Screenshots (PNG, no shadow, Desktop)
- [x] Control center (battery %, menu bar items)
- [x] Trim REFERENCES.md (removed verbose examples)

### Phase 3: Application Management (Next)
- [ ] Audit installed applications (/Applications)
- [ ] Add essential apps to nix: Obsidian, Brave, Slack
- [ ] Review login items for nix management
- [ ] Configure launchd services where applicable

---

## Near-Term Goals

### Profile Variants
Extend current architecture with profile-specific modules:
- **development** - Language runtimes, IDEs, debugging tools
- **work** - Communication apps, VPNs
- **minimal** - Bare essentials for recovery

### Login Items Management
Evaluate nix-darwin options for managing:
- Raycast (currently manual)
- Granola
- Google Drive
- Obsidian
- Slack

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

See [REFERENCES.md](REFERENCES.md) for comprehensive documentation links.
