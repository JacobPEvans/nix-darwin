# Claude Code Plugin Marketplaces
#
# Defines available plugin marketplaces for Claude Code.
# Plugins are fetched on-demand when enabled.
#
# IMPORTANT: Marketplace URL Format and Plugin References
# ========================================================================
# INPUT FORMAT (what we define here):
#   type: "github"     (for GitHub repositories)
#   url: "owner/repo"  (GitHub org/repo format, NOT full URL)
#
# OUTPUT FORMAT (after transformation via lib/claude-registry.nix):
#   source: "github"
#   repo: <value from source.url>  # The actual GitHub path for fetching
#
# MARKETPLACE DISPLAY NAMES:
# - Standard: Key = "owner/repo", display name = repo (extracted by getMarketplaceName)
# - Special: Some marketplaces use org-name as display (e.g., WakaTime uses "wakatime")
# - Plugin references: "plugin-name@display-name" (e.g., "claude-code-wakatime@wakatime")
#
# SPECIAL CASES (key differs from owner/repo pattern):
# - WakaTime: Key = "wakatime", URL = "wakatime/claude-code-wakatime"
#   Official: claude plugin i claude-code-wakatime@wakatime
# - When in doubt, check the official plugin install command
#
# WHY THIS WORKS:
# - The toClaudeMarketplaceFormat function (lib/claude-registry.nix)
#   converts both "github" and "git" types to "source: github"
# - The source.url becomes the repo value in settings.json (for fetching)
# - The KEY becomes the display name (for plugin references)
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

    # ========================================================================
    # Time Tracking & Monitoring Marketplaces
    # ========================================================================
    # SPECIAL CASE: WakaTime uses org-name as marketplace ID
    # Official install: claude plugin i claude-code-wakatime@wakatime
    # Key is "wakatime" (display name), URL is full GitHub path for fetching
    "wakatime" = {
      source = {
        type = "github";
        url = "wakatime/claude-code-wakatime";
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
