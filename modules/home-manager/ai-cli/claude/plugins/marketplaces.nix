# Claude Code Plugin Marketplaces
#
# Defines available plugin marketplaces for Claude Code.
# Plugins are fetched on-demand when enabled.
#
# IMPORTANT: Marketplace URL Format
# ========================================================================
# INPUT FORMAT (what we define here):
#   type: "github"     (for GitHub repositories)
#   url: "owner/repo"  (GitHub org/repo format, NOT full URL)
#
# OUTPUT FORMAT (after transformation via lib/claude-registry.nix):
#   source: "github"
#   repo: "marketplace-key"
#
# WHY THIS WORKS:
# - The toClaudeMarketplaceFormat function (lib/claude-registry.nix)
#   converts both "github" and "git" types to "source: github"
# - The marketplace key becomes the repo value
# - This ensures Claude Code can locate and fetch the marketplace
# ========================================================================

{ lib, ... }:

let
  # Validate marketplace entry has correct nested structure
  # Claude Code schema: { "id": { source: { type: "git", url: "..." } } }
  validateMarketplace =
    name: value:
    assert lib.assertMsg (builtins.isAttrs value)
      "Marketplace '${name}' must be an attrset, got ${builtins.typeOf value}";
    assert lib.assertMsg (
      value ? source && builtins.isAttrs value.source
    ) "Marketplace '${name}' must have a 'source' attrset";
    assert lib.assertMsg (
      value.source ? type && builtins.isString value.source.type
    ) "Marketplace '${name}.source' must have a 'type' string (git, github, local)";
    assert lib.assertMsg (
      value.source ? url && builtins.isString value.source.url
    ) "Marketplace '${name}.source' must have a 'url' string";
    true;

  marketplaces = {
    # ========================================================================
    # Official Anthropic Marketplaces
    # ========================================================================
    # Keys must be full GitHub paths (owner/repo) for correct transformation
    "anthropics/claude-plugins-official" = {
      source = {
        type = "github";
        url = "anthropics/claude-plugins-official";
      };
    };

    # ========================================================================
    # Community Marketplaces
    # ========================================================================
    "ananddtyagi/cc-marketplace" = {
      source = {
        type = "github";
        url = "ananddtyagi/cc-marketplace";
      };
    };
    "BillChirico/bills-claude-skills" = {
      source = {
        type = "github";
        url = "BillChirico/bills-claude-skills";
      };
    };
    "obra/superpowers-marketplace" = {
      source = {
        type = "github";
        url = "obra/superpowers-marketplace";
      };
    };

    # ========================================================================
    # Infrastructure & DevOps Marketplaces
    # ========================================================================
    "basher83/lunar-claude" = {
      source = {
        type = "github";
        url = "basher83/lunar-claude";
      };
    };
    "jeremylongshore/claude-code-plugins-plus" = {
      source = {
        type = "github";
        url = "jeremylongshore/claude-code-plugins-plus";
      };
    };
    "wshobson/agents" = {
      source = {
        type = "github";
        url = "wshobson/agents";
      };
    };
  };

  # Validate all marketplaces at evaluation time
  validatedMarketplaces = lib.mapAttrs validateMarketplace marketplaces;
in
# Force evaluation of validations
assert lib.all (x: x) (lib.attrValues validatedMarketplaces);
{
  inherit marketplaces;
}
