# Marketplace Documentation Index

Quick reference for all marketplace-related documentation.

## For Humans

- **[CLAUDE-MARKETPLACE-ARCHITECTURE.md](CLAUDE-MARKETPLACE-ARCHITECTURE.md)** - Architecture overview, how Claude works, what we learned

## For AI Agents

- **[TESTING-MARKETPLACES.md](TESTING-MARKETPLACES.md)** - Complete testing procedures, validation commands, troubleshooting

## Critical Files

All files now have comprehensive inline documentation:

| File | What It Does | Critical Fields |
|------|--------------|-----------------|
| `lib/claude-registry.nix` | Generates known_marketplaces.json | Keys must match manifest names; lastUpdated timestamp generation |
| `modules/.../marketplaces.nix` | Defines available marketplaces | Keys = manifest name; source.type = "github"; source.url = "owner/repo" |
| `modules/.../official.nix` | Official Anthropic plugins | Format: "plugin@marketplace" |
| `modules/.../development.nix` | Development plugins | All use @claude-code-workflows |
| `modules/.../infrastructure.nix` | Infrastructure plugins | Multiple marketplaces |
| `modules/.../registry.nix` | Registry generation | lastUpdated generation via printf |

## Quick Reference

### Marketplace Names (CRITICAL)

| GitHub Repo | Manifest Name | Use In Nix |
|-------------|---------------|------------|
| `anthropics/skills` | `anthropic-agent-skills` | `anthropic-agent-skills` |
| `wshobson/agents` | `claude-code-workflows` | `claude-code-workflows` |
| `anthropics/claude-plugins-official` | `claude-plugins-official` | `claude-plugins-official` |

### Plugin Reference Format

```nix
"plugin-name@marketplace-name"

# Correct:
"example-skills@anthropic-agent-skills"
"backend-dev@claude-code-workflows"

# Wrong:
"example-skills@skills"  # marketplace is anthropic-agent-skills
"backend-dev@agents"     # marketplace is claude-code-workflows
```

### How to Find Manifest Names

```bash
jq -r '.name' ~/.claude/plugins/marketplaces/*/.claude-plugin/marketplace.json
```

See [TESTING-MARKETPLACES.md](TESTING-MARKETPLACES.md) for complete details.

## Documentation Standards

Each Nix config file MUST have:

1. Header comment explaining what it does
2. CRITICAL section documenting required field formats
3. Examples showing correct vs incorrect usage
4. Reference to TESTING-MARKETPLACES.md for verification

## Version History

- **2025-12-31:** Complete documentation overhaul
  - Added comprehensive inline documentation to all files
  - Created TESTING-MARKETPLACES.md for AI testing
  - Fixed all marketplace keys to match manifest names
  - Fixed all plugin references
