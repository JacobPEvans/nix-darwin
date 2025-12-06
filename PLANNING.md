# Project Planning & Roadmap

**Future work and in-progress tasks only. For completed work, see [CHANGELOG.md](CHANGELOG.md).**

## Table of Contents

- [Repository Context](#repository-context)
- [Near-Term Goals](#near-term-goals)
- [Long-Term Vision](#long-term-vision)
- [Known Limitations](#known-limitations)
- [Maintenance Plan](#maintenance-plan)
- [Resources](#resources)

---

## Repository Context

- **Purpose**: Multi-host declarative system management
- **Architecture**: hosts + modules pattern with shared lib/ configs
- **Active Host**: M4 Max MacBook Pro (128GB RAM)
- **Templates**: Ubuntu server, Proxmox server, Windows workstation (placeholder)
- **Tools**: nix-darwin 25.05, home-manager 25.05, Determinate Nix

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

1. **Nix Settings Warnings**: Harmless forward-compatibility warnings from Determinate Nix (`eval-cores`, `lazy-trees`)

## Maintenance Plan

**Weekly**: Commit config tweaks, test darwin-rebuild

**Monthly**:

- `nix flake update` to update all inputs including Anthropic repositories
- Garbage collect old generations
- Review CHANGELOG for recent changes

**Quarterly**:

- Audit packages and plugin configurations
- Review enabled Claude Code plugins
- Update documentation
- Test SDK development shells

### Anthropic Ecosystem Maintenance

The comprehensive Anthropic Claude Code integration requires periodic updates:

**Plugin Updates** (Monthly):

```bash
nix flake lock --update-input claude-code-plugins
nix flake lock --update-input claude-cookbooks
nix flake lock --update-input claude-plugins-official
nix flake lock --update-input anthropic-skills
```

Then rebuild (see [RUNBOOK.md](RUNBOOK.md#everyday-commands)).

**Verify Integration** (After Updates):

- Run `/help` in Claude Code to verify all 12 plugins load
- Check `~/.claude/settings.json` for marketplace configuration
- Test cookbook commands: `/review-pr`, `/review-issue`
- Verify SDK shells: `nix develop ~/.config/nix/shells/claude-sdk-python`

**Documentation**: See [docs/ANTHROPIC-ECOSYSTEM.md](docs/ANTHROPIC-ECOSYSTEM.md) for complete reference.

## Resources

See [REFERENCES.md](REFERENCES.md) for comprehensive documentation links.
