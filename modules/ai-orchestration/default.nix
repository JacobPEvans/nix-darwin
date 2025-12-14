# AI Orchestration Master Module
#
# Provides multi-model AI orchestration capabilities:
# - PAL MCP Server for model routing
# - LiteLLM proxy for fallback
# - Anthropic Skills integration
# - Model benchmarking tools
# - Generic agent definitions
#
# This is a standalone module, NOT under ai-cli.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai-orchestration;
in
{
  imports = [
    ./benchmark
    ./pal-mcp
    ./litellm
    ./skills
    ./agents
  ];

  options.services.ai-orchestration = {
    enable = lib.mkEnableOption "Multi-model AI orchestration";

    localOnlyMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use only local Ollama models (no cloud APIs).
        When true, all tasks route to local models regardless of task type.
      '';
    };

    defaultResearchModel = lib.mkOption {
      type = lib.types.str;
      default = "gemini-3-pro";
      description = "Model for research tasks (can be local or cloud)";
    };

    defaultCodingModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-opus-4-5";
      description = "Model for complex coding tasks";
    };

    defaultFastModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-sonnet-4-5";
      description = "Model for quick, standard tasks";
    };

    localResearchModel = lib.mkOption {
      type = lib.types.str;
      default = "ollama/qwen3-next:80b";
      description = "Local model for research tasks when localOnlyMode is true";
    };

    localCodingModel = lib.mkOption {
      type = lib.types.str;
      default = "ollama/qwen3-coder:30b";
      description = "Local model for coding tasks when localOnlyMode is true";
    };

    secretsBackend = lib.mkOption {
      type = lib.types.enum [ "keychain" "bitwarden" "aws-vault" ];
      default = "keychain";
      description = ''
        How to retrieve API keys at runtime.
        Keys are NEVER stored in files or environment variables.
        - keychain: macOS Keychain (ai-secrets keychain)
        - bitwarden: Bitwarden Secrets Manager (bws)
        - aws-vault: AWS Vault for AWS credentials
      '';
    };

    ollamaHost = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434";
      description = "Ollama API endpoint";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable submodules by default
    services.ai-orchestration.benchmark.enable = lib.mkDefault true;
    services.ai-orchestration.pal-mcp.enable = lib.mkDefault true;
    services.ai-orchestration.litellm.enable = lib.mkDefault true;
    services.ai-orchestration.skills.enable = lib.mkDefault true;
    services.ai-orchestration.agents.enable = lib.mkDefault true;

    # Environment variable for local-only mode
    home.sessionVariables = lib.mkIf cfg.localOnlyMode {
      AI_ORCHESTRATION_LOCAL_ONLY = "true";
    };
  };
}
