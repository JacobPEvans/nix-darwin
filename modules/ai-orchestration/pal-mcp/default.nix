# AI Orchestration - PAL MCP Server Module
#
# PAL (Provider Abstraction Layer) MCP Server enables:
# - Multi-model orchestration (Gemini, Ollama, OpenRouter, etc.)
# - Tools: chat, clink, consensus, planner, codereview, precommit
# - Automatic model selection or explicit routing
#
# Installed via Nix flake input, not git clone.
# Secrets are retrieved at runtime from the configured backend (keychain [default], bws, or aws-vault), NEVER stored.
{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:

let
  cfg = config.services.ai-orchestration.pal-mcp;
  parentCfg = config.services.ai-orchestration;

  # Secrets retrieval command based on backend
  secretsCmd =
    if parentCfg.secretsBackend == "keychain" then
      "security find-generic-password -w -s"
    else if parentCfg.secretsBackend == "bitwarden" then
      "bws secret get"
    else
      "aws-vault exec default -- printenv";

in
{
  options.services.ai-orchestration.pal-mcp = {
    enable = lib.mkEnableOption "PAL MCP Server for multi-model orchestration";

    disabledTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "analyze"
        "refactor"
        "testgen"
        "secaudit"
        "docgen"
        "tracer"
      ];
      description = "Tools to disable (reduces context usage)";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "gemini-3-pro";
      description = "Default model for PAL operations";
    };
  };

  config = lib.mkIf cfg.enable {
    # PAL MCP will be pulled via flake input
    # For now, use uvx to run directly from GitHub
    home.packages = [
      pkgs.uv # For uvx command
    ];

    # PAL MCP wrapper that injects secrets at runtime
    home.file.".local/bin/pal-mcp-wrapper" = {
      executable = true;
      text = ''
        #!/usr/bin/env python3
        """PAL MCP wrapper that injects secrets from supported backends: keychain, bitwarden, aws-vault."""
        import os
        import shlex
        import subprocess
        import sys

        def get_secret(name: str) -> str:
            """Retrieve secret at runtime - NEVER stored in files."""
            try:
                result = subprocess.run(
                    shlex.split("${secretsCmd}") + [name],
                    capture_output=True,
                    text=True,
                    check=True
                )
                return result.stdout.strip()
            except subprocess.CalledProcessError:
                print(f"Warning: Could not retrieve {name}", file=sys.stderr)
                return ""

        # Inject secrets into environment (runtime only)
        os.environ["GEMINI_API_KEY"] = get_secret("GEMINI_API_KEY")
        os.environ["OPENAI_API_KEY"] = get_secret("OPENAI_API_KEY")
        os.environ["ANTHROPIC_API_KEY"] = get_secret("ANTHROPIC_API_KEY")
        os.environ["OLLAMA_HOST"] = "${parentCfg.ollamaHost}"
        os.environ["DEFAULT_MODEL"] = "${cfg.defaultModel}"
        os.environ["DISABLED_TOOLS"] = "${lib.concatStringsSep "," cfg.disabledTools}"

        # Launch PAL MCP via uvx
        os.execvp("uvx", [
            "uvx",
            "--from", "git+https://github.com/BeehiveInnovations/pal-mcp-server.git",
            "pal-mcp-server"
        ] + sys.argv[1:])
      '';
    };

    # Claude MCP server configuration
    # This will be merged with other MCP servers in the claude settings
    xdg.configFile."ai-orchestration/mcp-servers/pal.json".text = builtins.toJSON {
      pal = {
        command = "${config.home.homeDirectory}/.local/bin/pal-mcp-wrapper";
        args = [ ];
        env = {
          # Secrets injected at runtime by wrapper, not here
          OLLAMA_HOST = parentCfg.ollamaHost;
        };
      };
    };
  };
}
