# MCP Servers Configuration
#
# Simple, portable MCP server definitions using standard commands.
# Uses bunx for npm packages (faster than npx, auto-installs).
# Uses binary names for nixpkgs packages (resolved via PATH).
#
# Official MCP Servers: https://github.com/modelcontextprotocol/servers
#
# Note: Servers requiring API keys read them from environment variables.
# Use your secrets manager (Doppler, Keychain, etc.) to inject env vars.

{ pkgs, lib, ... }:

let
  # Helper to create stdio MCP server definition
  mkServer =
    {
      enabled ? false,
      command,
      args ? [ ],
      env ? { },
    }:
    {
      inherit enabled command args;
    }
    // lib.optionalAttrs (env != { }) { inherit env; };

  # Helper to create SSE/HTTP MCP server definition (remote, no local process)
  mkRemoteServer =
    {
      enabled ? false,
      type ? "sse",
      url,
      headers ? { },
    }:
    {
      inherit enabled type url;
    }
    // lib.optionalAttrs (headers != { }) { inherit headers; };

  # Official MCP server via bunx (fast, auto-installs)
  officialServer =
    {
      name,
      enabled ? false,
    }:
    mkServer {
      inherit enabled;
      command = "bunx";
      args = [ "@modelcontextprotocol/server-${name}" ];
    };

  # Wrap an MCP server command with Doppler secret injection.
  # The doppler-mcp script is defined in ai-tools.nix.
  # Usage: withDoppler (mkServer { command = "uvx"; args = [...]; enabled = true; })
  # Produces: { command = "doppler-mcp"; args = ["uvx" ...]; enabled = true; }
  #
  # Note: always pass the result of mkServer/officialServer, not a raw attrset.
  # mkServer guarantees command and args are present; withDoppler uses `or []`
  # as a safety net for args in case a caller omits it.
  withDoppler =
    server:
    server
    // {
      command = "doppler-mcp";
      args = [ server.command ] ++ (server.args or [ ]);
    };

  # All server definitions
  allServers = {
    # ================================================================
    # Official Anthropic MCP Servers (via bunx)
    # ================================================================

    everything = officialServer {
      name = "everything";
      enabled = true;
    };
    fetch = officialServer {
      name = "fetch";
      enabled = true;
    };
    filesystem = officialServer {
      name = "filesystem";
      enabled = true;
    };
    git = officialServer {
      name = "git";
      enabled = true;
    };
    memory = officialServer {
      name = "memory";
      enabled = true;
    };
    sequentialthinking = officialServer {
      name = "sequentialthinking";
      enabled = true;
    };
    time = officialServer {
      name = "time";
      enabled = true;
    };
    docker = officialServer {
      name = "docker";
      enabled = true;
    };
    exa = officialServer {
      name = "exa";
      enabled = true;
    };
    firecrawl = officialServer {
      name = "firecrawl";
      enabled = true;
    };
    cloudflare = officialServer {
      name = "cloudflare";
      enabled = true;
    };
    aws = officialServer {
      name = "aws-kb-retrieval";
      enabled = true;
    };

    # ================================================================
    # Native nixpkgs packages (binary name, resolved via PATH)
    # ================================================================

    # Terraform - terraform-mcp-server from nixpkgs
    terraform = mkServer {
      enabled = true;
      command = "terraform-mcp-server";
    };

    # GitHub - github-mcp-server from nixpkgs
    # Requires: GITHUB_PERSONAL_ACCESS_TOKEN env var
    github = mkServer {
      enabled = true;
      command = "github-mcp-server";
    };

    # ================================================================
    # Third-party npm packages (via bunx)
    # ================================================================

    # Context7 - Library documentation lookup
    context7 = mkServer {
      enabled = true;
      command = "bunx";
      args = [ "@context7/mcp-server" ];
    };

    # ================================================================
    # PAL MCP - Multi-model orchestration
    # ================================================================
    # Provider Abstraction Layer for routing tasks to different AI models
    # Tools (all enabled): chat, thinkdeep, planner, codereview, precommit, debug,
    #   apilookup, challenge, clink, consensus, analyze, refactor, testgen, secaudit,
    #   docgen, tracer
    # See: https://github.com/BeehiveInnovations/pal-mcp-server
    #
    # API keys injected via Doppler (withDoppler wrapper, at least one required):
    #   - GEMINI_API_KEY (Google Gemini)
    #   - OPENROUTER_API_KEY (OpenRouter - unified model access)
    #   - OLLAMA_HOST (local Ollama server URL)
    #
    # Non-secret config is set in env below (belongs in Nix, not Doppler).

    pal = withDoppler (mkServer {
      enabled = true;
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/BeehiveInnovations/pal-mcp-server.git"
        "pal-mcp-server"
      ];
      env = {
        # Enable ALL PAL tools (default disables: analyze,refactor,testgen,secaudit,docgen,tracer)
        DISABLED_TOOLS = "";
        # Conversation limits
        CONVERSATION_TIMEOUT_HOURS = "6";
        MAX_CONVERSATION_TURNS = "50";
        LOG_LEVEL = "INFO";
      };
    });

    # ================================================================
    # Obsidian - NOT IMPLEMENTED
    # ================================================================
    # Decision: Not moving forward with REST API approach since official Obsidian CLI will be released soon.
    # Using Claude Skills plugins for Obsidian integration instead (see plugins/community.nix).
    #
    # If revisited in the future:
    # - Use `uvx mcp-obsidian` (PyPI package)
    # - Requires Obsidian REST API plugin: https://github.com/coddingtonbear/obsidian-local-rest-api
    # - IMPORTANT: Inject OBSIDIAN_API_KEY via secrets manager at runtime (never in Nix store)
    # - Non-secret defaults: OBSIDIAN_HOST=127.0.0.1, OBSIDIAN_PORT=27124

    # ================================================================
    # Database (disabled by default)
    # ================================================================

    postgresql = officialServer {
      name = "postgres";
      enabled = false;
    };
    sqlite = officialServer {
      name = "sqlite";
      enabled = false;
    };

    # ================================================================
    # Additional (disabled - specialized use cases)
    # ================================================================

    brave-search = officialServer {
      name = "brave-search";
      enabled = false;
    };
    gdrive = officialServer {
      name = "gdrive";
      enabled = false;
    };
    google-maps = officialServer {
      name = "google-maps";
      enabled = false;
    };
    puppeteer = officialServer {
      name = "puppeteer";
      enabled = false;
    };
    slack = officialServer {
      name = "slack";
      enabled = false;
    };
    sentry = officialServer {
      name = "sentry";
      enabled = false;
    };

    # ================================================================
    # Cribl MCP - OrbStack kubernetes-monitoring stack
    # ================================================================
    # Cribl MCP server running in OrbStack k8s cluster (NodePort :30030).
    # Connection will fail when OrbStack k8s is not running — this is expected.
    # See: ~/git/kubernetes-monitoring for the stack configuration.
    cribl = mkRemoteServer {
      enabled = true;
      url = "http://localhost:30030/mcp";
    };
  };

  # Filter to enabled servers, strip the internal `enabled` flag.
  # settings.nix handles the final transformation to Claude Code JSON format.
  enabledServers = lib.filterAttrs (_: v: v.enabled) allServers;
  mcpServersForClaude = lib.mapAttrs (_: v: builtins.removeAttrs v [ "enabled" ]) enabledServers;

in
{
  mcpServers = mcpServersForClaude;
}
