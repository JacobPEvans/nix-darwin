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
  # Helper to create MCP server config entry
  mkServer =
    {
      enabled ? false,
      command,
      args ? [ ],
    }:
    {
      inherit command args;
    }
    // lib.optionalAttrs (!enabled) { enable = false; }
    // lib.optionalAttrs enabled { enable = true; };

  # Helper to fetch MCP server from official modelcontextprotocol repo
  # This is Anthropic's official MCP servers repository
  officialServer =
    {
      name,
      hash,
    }:
    mkServer {
      command = "${pkgs.nodejs}/bin/node";
      args = [
        "${
          pkgs.fetchFromGitHub {
            owner = "modelcontextprotocol";
            repo = "servers";
            rev = "main";
            sparseCheckout = [ "src/${name}" ];
            sha256 = hash;
          }
        }/src/${name}/dist/index.js"
      ];
    };

in
{
  # Export mcpServers for use in claude-config.nix
  # These are then merged into the programs.claude.mcpServers setting
  mcpServers = {
    # ================================================================
    # Official Anthropic MCP Servers (modelcontextprotocol/servers)
    # ALL enabled by default
    # ================================================================

    # Everything - Reference/test server with prompts, resources, and tools
    everything =
      (officialServer {
        name = "everything";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Fetch - Web content fetching and conversion for efficient LLM usage
    fetch =
      (officialServer {
        name = "fetch";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Filesystem - Secure file operations with configurable access controls
    filesystem =
      (officialServer {
        name = "filesystem";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Git - Tools for git repository manipulation
    git =
      (officialServer {
        name = "git";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Memory - Knowledge graph-based persistent context
    memory =
      (officialServer {
        name = "memory";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Sequential Thinking - Problem-solving through thought sequences
    sequentialthinking =
      (officialServer {
        name = "sequentialthinking";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Time - Timezone conversion utilities
    time =
      (officialServer {
        name = "time";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # ================================================================
    # Infrastructure & DevOps (Native nixpkgs packages)
    # ================================================================

    # Terraform - Available in nixpkgs as native package
    terraform = mkServer {
      enabled = true;
      command = "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server";
    };

    # GitHub - Available in nixpkgs as native package
    # Requires: GITHUB_PERSONAL_ACCESS_TOKEN env var
    github = mkServer {
      enabled = true;
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
    };

    # Docker - Container management via docker CLI
    docker = mkServer {
      enabled = true;
      command = "${pkgs.docker}/bin/docker";
    };

    # ================================================================
    # Search (from official MCP servers repo)
    # ================================================================

    # Exa - AI-focused semantic search
    # Requires: EXA_API_KEY env var
    exa =
      (officialServer {
        name = "exa";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # Firecrawl - Web scraping for LLMs
    # Requires: FIRECRAWL_API_KEY env var
    firecrawl =
      (officialServer {
        name = "firecrawl";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # ================================================================
    # Cloud Services (from official MCP servers repo)
    # ================================================================

    # Cloudflare - Workers, KV, R2, D1 management
    # Requires: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID env vars
    cloudflare =
      (officialServer {
        name = "cloudflare";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # AWS - Multi-service AWS integration
    # Requires: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION env vars
    aws =
      (officialServer {
        name = "aws-kb-retrieval-server";
        hash = lib.fakeHash;
      })
      // {
        enable = true;
      };

    # ================================================================
    # Database (disabled by default - require setup)
    # ================================================================

    # PostgreSQL - Database queries with natural language
    # Requires: DATABASE_URL env var
    postgresql =
      (officialServer {
        name = "postgres";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # SQLite - Local database queries
    # Requires: SQLITE_DB_PATH env var
    sqlite =
      (officialServer {
        name = "sqlite";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # ================================================================
    # Additional Official Servers (disabled - specialized use cases)
    # ================================================================

    # Brave Search - Web search capabilities
    # Requires: BRAVE_API_KEY env var
    brave-search =
      (officialServer {
        name = "brave-search";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # Google Drive - Google Drive file access
    # Requires: GDRIVE_CREDENTIALS env var
    gdrive =
      (officialServer {
        name = "gdrive";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # Google Maps - Location and mapping services
    # Requires: GOOGLE_MAPS_API_KEY env var
    google-maps =
      (officialServer {
        name = "google-maps";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # Puppeteer - Browser automation (alternative to Playwright)
    puppeteer =
      (officialServer {
        name = "puppeteer";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # Slack - Team communication integration
    # Requires: SLACK_BOT_TOKEN, SLACK_TEAM_ID env vars
    slack =
      (officialServer {
        name = "slack";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };

    # Sentry - Error tracking and monitoring
    # Requires: SENTRY_AUTH_TOKEN env var
    sentry =
      (officialServer {
        name = "sentry";
        hash = lib.fakeHash;
      })
      // {
        enable = false;
      };
  };
}
