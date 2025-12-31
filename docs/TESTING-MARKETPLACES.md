# Marketplace Testing Guide

For AI Agents: Complete testing procedures for Claude Code marketplace configuration

## Quick Reference: How to Find Marketplace Names

### Method 1: From Cloned Marketplace

```bash
# After Claude clones the marketplace to ~/.claude/plugins/marketplaces/
jq -r '.name' ~/.claude/plugins/marketplaces/*/.claude-plugin/marketplace.json
```

### Method 2: From GitHub (Before Cloning)

```bash
curl -s https://raw.githubusercontent.com/OWNER/REPO/main/.claude-plugin/marketplace.json | jq -r '.name'
```

### Method 3: Scan All Local Marketplaces

```bash
for dir in ~/.claude/plugins/marketplaces/*/; do
  name=$(basename "$dir")
  manifest="$dir/.claude-plugin/marketplace.json"
  if [ -f "$manifest" ]; then
    actual_name=$(jq -r '.name // "MISSING"' "$manifest")
    echo "$name → $actual_name"
  fi
done
```

## Complete Marketplace Reference

| GitHub Repo | Manifest Name | Nix Key | Status |
|-------------|---------------|---------|--------|
| `anthropics/claude-plugins-official` | `claude-plugins-official` | `claude-plugins-official` | ✓ |
| `anthropics/skills` | `anthropic-agent-skills` | `anthropic-agent-skills` | ✓ |
| `wshobson/agents` | `claude-code-workflows` | `claude-code-workflows` | ✓ |
| `ananddtyagi/cc-marketplace` | `cc-marketplace` | `cc-marketplace` | ✓ |
| `BillChirico/bills-claude-skills` | `bills-claude-skills` | `bills-claude-skills` | ✓ |
| `obra/superpowers-marketplace` | `superpowers-marketplace` | `superpowers-marketplace` | ✓ |
| `basher83/lunar-claude` | `lunar-claude` | `lunar-claude` | ✓ |
| `jeremylongshore/claude-code-plugins-plus` | `claude-code-plugins-plus` | `claude-code-plugins-plus` | ✓ |
| `wakatime/claude-code-wakatime` | `wakatime` | `wakatime` | ✓ |

## Testing Procedure

### 1. Test From Clean State

```bash
# Remove Claude-managed files (Nix will recreate symlinks on rebuild)
rm -rf ~/.claude/plugins/marketplaces/local
rm -f ~/.claude/plugins/known_marketplaces.json

# Rebuild
sudo darwin-rebuild switch --flake .

# Verify marketplaces load without errors
claude plugin marketplace list
```

**Expected output:** No warnings about "Failed to load marketplace"

### 2. Verify Marketplace Names

```bash
# Check that Nix-generated names match Claude's expectations
jq 'keys[]' ~/.claude/plugins/known_marketplaces.json | sort

# Should show:
# "anthropic-agent-skills"
# "bills-claude-skills"
# "cc-marketplace"
# "claude-code-plugins-plus"
# "claude-code-workflows"
# "claude-plugins-official"
# "lunar-claude"
# "superpowers-marketplace"
# "wakatime"
```

**Note:** NO "local" marketplace should exist (this was a Nix-only concept, not used by Claude)

### 3. Verify Plugin References

```bash
# Check enabled plugins reference correct marketplaces
jq '.enabledPlugins | keys[] | select(contains("skills") or contains("workflows"))' ~/.claude/settings.json

# Should show:
# "document-skills@anthropic-agent-skills"  ✓ (not @skills)
# "example-skills@anthropic-agent-skills"   ✓ (not @skills)
# "backend-development@claude-code-workflows" ✓ (not @agents)
```

### 4. Verify File Permissions

```bash
# Nix-managed files should be read-only symlinks
ls -la ~/.claude/plugins/known_marketplaces.json
# Expected: lrwxr-xr-x ... -> /nix/store/...

ls -la ~/.claude/settings.json
# Expected: lrwxr-xr-x ... -> /nix/store/...
```

**Why this matters:** Claude can't update these files at runtime, which is correct for Nix-managed configuration.

### 5. Test Marketplace Cloning

```bash
# Let Claude clone a marketplace fresh
rm -rf ~/.claude/plugins/marketplaces/anthropic-agent-skills
rm -f ~/.claude/plugins/known_marketplaces.json

# Start Claude - it should clone missing marketplaces
claude

# Verify it cloned correctly
ls ~/.claude/plugins/marketplaces/anthropic-agent-skills/.claude-plugin/marketplace.json
jq '.name' ~/.claude/plugins/marketplaces/anthropic-agent-skills/.claude-plugin/marketplace.json
# Expected: "anthropic-agent-skills"
```

## Common Errors and Fixes

### Error: "Failed to load marketplace 'local'"

**Cause:** Nix config created a `local` marketplace entry but Claude doesn't use this.

**Fix:** Ensure `lib/claude-registry.nix` does NOT create a "local" entry. It was removed in 2025-12-31.

### Error: "Invalid schema: name: Required, owner: Required"

**Cause:** marketplace.json missing required fields.

**Fix:** Claude Code requires:

```json
{
  "name": "marketplace-name",
  "owner": { "name": "Owner Name" },
  "plugins": []
}
```

NOT:

```json
{"id":"local","plugins":[]}  // ✗ WRONG
```

### Error: Plugin not found "example-skills@skills"

**Cause:** Plugin reference uses wrong marketplace name.

**Fix:** Change `@skills` to `@anthropic-agent-skills` (the actual manifest name).

Check: `jq '.name' ~/.claude/plugins/marketplaces/*/.claude-plugin/marketplace.json`

### Error: Plugin not found "backend-dev@agents"

**Cause:** Plugin reference uses GitHub repo path instead of manifest name.

**Fix:** Change `@agents` to `@claude-code-workflows` (the actual manifest name).

## Validation Commands

### Quick Health Check

```bash
# All-in-one validation
{
  echo "=== Marketplaces ==="
  claude plugin marketplace list 2>&1 | grep -E "(^  ❯|Warning|Error)" || echo "No errors"

  echo -e "\n=== Registry Keys ==="
  jq -r 'keys[]' ~/.claude/plugins/known_marketplaces.json | sort

  echo -e "\n=== Plugin References (sample) ==="
  jq -r '.enabledPlugins | keys[] | select(contains("skills") or contains("workflows"))' ~/.claude/settings.json | head -5

  echo -e "\n=== File Permissions ==="
  ls -la ~/.claude/plugins/known_marketplaces.json | awk '{print $1, $NF}'
  ls -la ~/.claude/settings.json | awk '{print $1, $NF}'
}
```

### Deep Validation

```bash
# Verify EVERY marketplace name matches its manifest
for dir in ~/.claude/plugins/marketplaces/*/; do
  registry_key=$(basename "$dir")
  manifest_name=$(jq -r '.name' "$dir/.claude-plugin/marketplace.json" 2>/dev/null)
  nix_key=$(jq -r --arg rk "$registry_key" 'to_entries[] | select(.value.installLocation | contains($rk)) | .key' ~/.claude/plugins/known_marketplaces.json)

  if [ "$manifest_name" != "$nix_key" ]; then
    echo "❌ MISMATCH: registry=$registry_key nix=$nix_key manifest=$manifest_name"
  else
    echo "✓ $manifest_name"
  fi
done
```

## Critical Files Reference

| File | Purpose | Managed By | Writable |
|------|---------|------------|----------|
| `~/.claude/plugins/known_marketplaces.json` | Marketplace registry | Nix (symlink) | No |
| `~/.claude/settings.json` | Plugin configuration | Nix (symlink) | No |
| `~/.claude/plugins/installed_plugins.json` | Plugin state | Claude | Yes |
| `~/.claude/plugins/marketplaces/<name>/` | Cloned marketplace | Claude | Yes |

## Nix Configuration Reference

| File | What to Check |
|------|---------------|
| `lib/claude-registry.nix` | lastUpdated parameter passed; No "local" marketplace |
| `modules/.../plugins/marketplaces.nix` | Keys match manifest names; source.type = "github"; source.url = "owner/repo" |
| `modules/.../plugins/official.nix` | Plugin refs use @anthropic-agent-skills; NOT @skills |
| `modules/.../plugins/development.nix` | All refs use @claude-code-workflows; NOT @agents |
| `modules/.../plugins/infrastructure.nix` | Refs use correct marketplace names |

## For AI Agents: Automated Testing

When validating marketplace configuration changes:

1. **Always test from clean state** (remove files, rebuild)
2. **Verify marketplace names match manifests** (use scan script above)
3. **Check for warnings** in `claude plugin marketplace list`
4. **Validate plugin references** match marketplace keys
5. **Document any mismatches** for manual fix

## Version History

- **2025-12-31:** Initial testing guide
  - Removed local marketplace
  - Fixed all marketplace keys to match manifests
  - Fixed all plugin references
