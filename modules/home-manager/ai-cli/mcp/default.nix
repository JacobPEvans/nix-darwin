# MCP Servers Configuration - Nix-Native
#
# Strategy: Avoid runtime npm/npx/bunx entirely
# All MCP servers are either:
# 1. Native nixpkgs packages (terraform-mcp-server, github-mcp-server, etc.)
# 2. Fetched and cached from GitHub (official MCP servers from modelcontextprotocol)
#
# No runtime dependency installation - everything is deterministic and cached.
#
# Official MCP Servers: https://github.com/modelcontextprotocol/servers
#
# Note: Servers requiring API keys will read them from environment variables.
# Use your secrets manager (Doppler, Keychain, etc.) to inject env vars at runtime.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Helper to create MCP server definition with enable flag
  # The enable flag is used for filtering, not passed to programs.claude
  mkServerDef =
    {
      enabled ? false,
      command,
      args ? [ ],
    }:
    {
      inherit enabled command args;
    };

  # Fetch the entire official MCP servers repository once
  # Pinned to commit: 861c11b786b3efbc87eb2e878a4039d33846a031 (2026-01-13)
  # Single fetch for all servers to avoid sparseCheckout hash non-determinism
  mcpServersRepo = pkgs.fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "servers";
    rev = "861c11b786b3efbc87eb2e878a4039d33846a031";
    sha256 = "sha256-qVlm+4iYoMcN/FP6kQF3++6Va6S42hgDp8PhOKBQlAI=";
  };

  # Helper to create server definition from the fetched repo
  officialServerDef =
    {
      name,
      enabled ? false,
    }:
    mkServerDef {
      inherit enabled;
      command = "${pkgs.nodejs}/bin/node";
      args = [ "${mcpServersRepo}/src/${name}/dist/index.js" ];
    };

  # All server definitions with enable flags
  # To enable/disable a server, change its `enabled` attribute
  allServers = {
    # ================================================================
    # Official Anthropic MCP Servers (modelcontextprotocol/servers)
    # ALL enabled by default
    # ================================================================

    # Everything - Reference/test server with prompts, resources, and tools
    everything = officialServerDef {
      name = "everything";
      enabled = true;
    };

    # Fetch - Web content fetching and conversion for efficient LLM usage
    fetch = officialServerDef {
      name = "fetch";
      enabled = true;
    };

    # Filesystem - Secure file operations with configurable access controls
    filesystem = officialServerDef {
      name = "filesystem";
      enabled = true;
    };

    # Git - Tools for git repository manipulation
    git = officialServerDef {
      name = "git";
      enabled = true;
    };

    # Memory - Knowledge graph-based persistent context
    memory = officialServerDef {
      name = "memory";
      enabled = true;
    };

    # Sequential Thinking - Problem-solving through thought sequences
    sequentialthinking = officialServerDef {
      name = "sequentialthinking";
      enabled = true;
    };

    # Time - Timezone conversion utilities
    time = officialServerDef {
      name = "time";
      enabled = true;
    };

    # ================================================================
    # Infrastructure & DevOps (Native nixpkgs packages)
    # ================================================================

    # Terraform - Available in nixpkgs as native package
    terraform = mkServerDef {
      enabled = true;
      command = "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server";
    };

    # GitHub - Available in nixpkgs as native package
    # Requires: GITHUB_PERSONAL_ACCESS_TOKEN env var
    github = mkServerDef {
      enabled = true;
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
    };

    # Docker - Container management via docker CLI
    docker = mkServerDef {
      enabled = true;
      command = "${pkgs.docker}/bin/docker";
    };

    # ================================================================
    # Search (from official MCP servers repo)
    # ================================================================

    # Exa - AI-focused semantic search
    # Requires: EXA_API_KEY env var
    exa = officialServerDef {
      name = "exa";
      enabled = true;
    };

    # Firecrawl - Web scraping for LLMs
    # Requires: FIRECRAWL_API_KEY env var
    firecrawl = officialServerDef {
      name = "firecrawl";
      enabled = true;
    };

    # ================================================================
    # Cloud Services (from official MCP servers repo)
    # ================================================================

    # Cloudflare - Workers, KV, R2, D1 management
    # Requires: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID env vars
    cloudflare = officialServerDef {
      name = "cloudflare";
      enabled = true;
    };

    # AWS - Multi-service AWS integration
    # Requires: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION env vars
    aws = officialServerDef {
      name = "aws-kb-retrieval-server";
      enabled = true;
    };

    # ================================================================
    # Database (disabled by default - require setup)
    # ================================================================

    # PostgreSQL - Database queries with natural language
    # Requires: DATABASE_URL env var
    postgresql = officialServerDef {
      name = "postgres";
      enabled = false;
    };

    # SQLite - Local database queries
    # Requires: SQLITE_DB_PATH env var
    sqlite = officialServerDef {
      name = "sqlite";
      enabled = false;
    };

    # ================================================================
    # Additional Official Servers (disabled - specialized use cases)
    # ================================================================

    # Brave Search - Web search capabilities
    # Requires: BRAVE_API_KEY env var
    brave-search = officialServerDef {
      name = "brave-search";
      enabled = false;
    };

    # Google Drive - Google Drive file access
    # Requires: GDRIVE_CREDENTIALS env var
    gdrive = officialServerDef {
      name = "gdrive";
      enabled = false;
    };

    # Google Maps - Location and mapping services
    # Requires: GOOGLE_MAPS_API_KEY env var
    google-maps = officialServerDef {
      name = "google-maps";
      enabled = false;
    };

    # Puppeteer - Browser automation (alternative to Playwright)
    puppeteer = officialServerDef {
      name = "puppeteer";
      enabled = false;
    };

    # Slack - Team communication integration
    # Requires: SLACK_BOT_TOKEN, SLACK_TEAM_ID env vars
    slack = officialServerDef {
      name = "slack";
      enabled = false;
    };

    # Sentry - Error tracking and monitoring
    # Requires: SENTRY_AUTH_TOKEN env var
    sentry = officialServerDef {
      name = "sentry";
      enabled = false;
    };
  };

  # Filter to only enabled servers and remove the `enabled` attribute
  # This is what gets passed to programs.claude.mcpServers
  enabledServers = lib.filterAttrs (_: v: v.enabled) allServers;
  mcpServersForClaude = lib.mapAttrs (_: v: {
    inherit (v) command args;
  }) enabledServers;

in
{
  # Export mcpServers for use in claude-config.nix
  # These are filtered to only enabled servers and formatted for programs.claude
  mcpServers = mcpServersForClaude;
}
