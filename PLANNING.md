# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Repository Context

- **Purpose**: Multi-host declarative system management
- **Architecture**: hosts + modules pattern with shared lib/ configs
- **Active Host**: M4 Max MacBook Pro (128GB RAM)
- **Templates**: Ubuntu server, Proxmox server, Windows workstation (placeholder)
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix

## Current Work: System Configuration Migration

**Branch**: `feat/system-config-migration`

### Phase 3: Application Management (In Progress)
- [x] Audit installed applications (/Applications)
- [x] Add Obsidian to nix (darwin/common.nix)
- [x] Add zoom-us to nix (darwin/common.nix)
- [x] Add Ollama CLI to nix (removed - nixpkgs build fails, using manual install)
- [x] Add mas (Mac App Store CLI) with masApps pattern
- [x] Add direnv + nix-direnv for per-project shells
- [x] Create shells/ directory with Python, Python-data, JS, Go templates
- [ ] Review remaining login items (Raycast already nix-managed)
- [ ] Evaluate launchd services for custom scripts

---

## Near-Term Goals

### Profile Variants
Extend current architecture with profile-specific modules:
- **development** - Language runtimes, IDEs, debugging tools
  - Python: ruff, black, mypy
  - JavaScript: prettier, eslint_d
  - YAML/TOML: yamllint, yamlfmt, taplo
  - Docker: hadolint
- **work** - Communication apps, VPNs
- **minimal** - Bare essentials for recovery

### Login Items Management
Evaluate nix-darwin options for managing:
- Raycast (nix-managed, login managed by app)
- Google Drive (manual, proprietary)
- Obsidian (nix-managed, login managed by app)
- Slack (manual for now)

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

---

## Known Limitations

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix
2. **Homebrew Exception**: claude-code via homebrew for rapid updates

## Maintenance Plan

**Weekly**: Commit config tweaks, test darwin-rebuild
**Monthly**: `nix flake update`, garbage collect, review CHANGELOG
**Quarterly**: Audit packages, update documentation

## Resources

See [REFERENCES.md](REFERENCES.md) for comprehensive documentation links.
