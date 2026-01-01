# Claude Code Marketplace Architecture

Status: RESOLVED (2025-12-31)

This document captures the architecture and learnings from marketplace configuration.

**For testing procedures, see [TESTING-MARKETPLACES.md](TESTING-MARKETPLACES.md)**

## Critical Discovery: How Claude Code Actually Works

### Marketplace Naming (IMPORTANT!)

**Claude uses the `name` field from each marketplace's `.claude-plugin/marketplace.json`, NOT our Nix config keys.**

| GitHub Repo | marketplace.json `name` | Our Nix Key (WRONG) |
|-------------|------------------------|---------------------|
| `anthropics/skills` | `anthropic-agent-skills` | `skills` |
| `wshobson/agents` | `claude-code-workflows` | `agents` |
| `anthropics/claude-plugins-official` | `claude-plugins-official` | (correct) |

**Implication:** Our `known_marketplaces.json` keys must match the `name` field from each marketplace's manifest, not our arbitrary names.

### The "local" Marketplace Myth

**Claude Code does NOT create a `local` marketplace by default.**

Our Nix config was creating:

```json
"local": {
  "source": { "source": "directory", "path": "~/.claude/plugins/marketplaces/local" },
  "installLocation": "...",
  "managedBy": "runtime"  // <-- Claude doesn't use this field!
}
```

But Claude never creates this. The `local` marketplace concept was a Nix-side invention that caused errors:

- "Failed to load marketplace 'local': Marketplace file not found"
- "Invalid schema: name: Required, owner: Required"

**Solution:** Remove the `local` marketplace from Nix config entirely, or only create it if the user explicitly wants a local plugin development directory.

### File Permissions and Writability

**Claude Code expects to WRITE to these files at runtime:**

- `~/.claude/plugins/known_marketplaces.json` - Updated with `lastUpdated` timestamps
- `~/.claude/plugins/installed_plugins.json` - Plugin installation state

**Nix symlinks to the store are READ-ONLY**, which breaks Claude's expectations.

**Current workaround options:**

1. Let Claude manage these files entirely (don't Nix-manage them)
2. Use activation scripts to copy (not symlink) from Nix store
3. Accept that timestamps won't update (cosmetic issue only)

### Claude-Generated known_marketplaces.json Structure

When Claude creates this file fresh, it looks like:

```json
{
  "marketplace-name": {
    "source": {
      "source": "github",
      "repo": "owner/repo"
    },
    "installLocation": "/Users/USER/.claude/plugins/marketplaces/marketplace-name",
    "lastUpdated": "2025-12-31T16:51:05.611Z"
  }
}
```

**Key observations:**

- No `managedBy` field
- `lastUpdated` has milliseconds (`.611Z`)
- `installLocation` uses full absolute path
- Keys match the marketplace's internal `name`, not the GitHub repo

## Error History and Root Causes

### Error: "Failed to load marketplace 'local'"

**Cause:** Nix config created a `local` entry pointing to a path where no valid `marketplace.json` existed.

**Fix:** Either:

- Remove `local` from `known_marketplaces.json` entirely
- Create a valid `marketplace.json` at the specified path with required `name` and `owner` fields

### Error: "Invalid schema: name: Required, owner: Required"

**Cause:** The `marketplace.json` file at `~/.claude/plugins/marketplaces/local/.claude-plugin/marketplace.json` contained:

```json
{"id":"local","plugins":[]}
```

But Claude requires:

```json
{
  "name": "local",
  "owner": { "name": "Your Name" },
  "plugins": []
}
```

**Fix:** Update the marketplace.json template in `modules/home-manager/ai-cli/claude/default.nix` activation script.

### Error: "Failed to install Anthropic marketplace"

**Cause:** Under investigation. May be related to:

- Network issues
- Missing default marketplace configuration
- Conflict between Nix-managed and Claude-managed state

## File Locations Reference

| File | Purpose | Managed By |
|------|---------|------------|
| `~/.claude/plugins/known_marketplaces.json` | Registry of configured marketplaces | Claude (runtime) or Nix |
| `~/.claude/plugins/installed_plugins.json` | State of installed/enabled plugins | Claude (runtime) |
| `~/.claude/plugins/marketplaces/<name>/` | Cloned marketplace repos | Claude (runtime) |
| `~/.claude/plugins/marketplaces/<name>/.claude-plugin/marketplace.json` | Marketplace manifest | From repo |

## Nix Configuration Files

| File | Purpose |
|------|---------|
| `lib/claude-registry.nix` | Pure functions for generating registry JSON |
| `modules/home-manager/ai-cli/claude/registry.nix` | Home-manager integration for known_marketplaces.json |
| `modules/home-manager/ai-cli/claude/plugins/marketplaces.nix` | Marketplace definitions |
| `modules/home-manager/ai-cli/claude/default.nix` | Activation scripts for directory setup |

## Plugin Reference Format

Plugins are referenced as `plugin-name@marketplace-name`.

**The marketplace-name must match the `name` field from the marketplace's manifest**, not the GitHub repo path.

| GitHub Repo | manifest `name` | Correct Plugin Reference |
|-------------|-----------------|--------------------------|
| `anthropics/skills` | `anthropic-agent-skills` | `example-skills@anthropic-agent-skills` |
| `wshobson/agents` | `claude-code-workflows` | `some-plugin@claude-code-workflows` |
| `anthropics/claude-plugins-official` | `claude-plugins-official` | `commit-commands@claude-plugins-official` |

**Our Nix config used wrong names like `example-skills@skills`** because we extracted the last path segment instead of reading the manifest.

## Recommended Architecture (TODO)

Based on findings, the ideal approach may be:

1. **Don't Nix-manage known_marketplaces.json** - Let Claude create and update it
2. **Use settings.json `extraKnownMarketplaces`** - Define marketplaces in settings, let Claude populate the registry
3. **Remove "local" marketplace** - Only create if user explicitly needs local plugin development
4. **Match marketplace names** - If we do manage the registry, use names from marketplace.json manifests

## Testing Procedure

**See [TESTING-MARKETPLACES.md](TESTING-MARKETPLACES.md) for complete testing procedures.**

Quick test:

```bash
rm -rf ~/.claude/plugins/marketplaces/local && rm -f ~/.claude/plugins/known_marketplaces.json
sudo darwin-rebuild switch --flake .
claude plugin marketplace list  # Should show no errors
```

## Complete Marketplace Name Mapping

| GitHub Repo | manifest `name` | Status |
|-------------|-----------------|--------|
| `anthropics/claude-plugins-official` | `claude-plugins-official` | Correct |
| `anthropics/skills` | `anthropic-agent-skills` | Fixed |
| `ananddtyagi/cc-marketplace` | `cc-marketplace` | Fixed |
| `BillChirico/bills-claude-skills` | `bills-claude-skills` | Fixed |
| `obra/superpowers-marketplace` | `superpowers-marketplace` | Fixed |
| `basher83/lunar-claude` | `lunar-claude` | Fixed |
| `jeremylongshore/claude-code-plugins-plus` | `claude-code-plugins-plus` | Fixed |
| `wshobson/agents` | `claude-code-workflows` | Fixed |
| `wakatime/claude-code-wakatime` | `wakatime` | Correct |

## Version History

- **2025-12-31:** Initial documentation after debugging session
  - Discovered `local` marketplace is not a Claude concept
  - Discovered marketplace naming comes from manifest `name` field
  - Documented required marketplace.json schema
  - Fixed all marketplace keys to match manifest names
  - Fixed all plugin references to use correct marketplace names
  - Removed `local` marketplace from Nix config
