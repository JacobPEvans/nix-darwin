# AI Orchestration - LiteLLM Module
#
# LiteLLM provides:
# - Unified API for multiple LLM providers
# - Fallback routing on errors
# - Cost tracking and budget limits
#
# This is a submodule of ai-orchestration, NOT under ai-cli.
# Migrated from modules/home-manager/ai-cli/litellm/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ai-orchestration.litellm;
  parentCfg = config.services.ai-orchestration;
  homeDir = config.home.homeDirectory;
  orbstackDir = "${homeDir}/OrbStack/ai-orchestration/litellm";

in
{
  options.services.ai-orchestration.litellm = {
    enable = lib.mkEnableOption "LiteLLM proxy (fallback routing)";

    maxBudgetUSD = lib.mkOption {
      type = lib.types.number;
      default = 50.0;
      description = "Daily USD budget before triggering fallback to local models";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "LiteLLM proxy port";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        (pkgs.python3.withPackages (ps: [ ps.litellm ]))
      ];

      # Helper scripts
      file = {
        ".local/bin/litellm-start" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            cd ~/.config/ai-orchestration/litellm
            docker-compose up -d
            echo "LiteLLM proxy started at http://localhost:${toString cfg.port}"
          '';
        };

        ".local/bin/litellm-stop" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            cd ~/.config/ai-orchestration/litellm
            docker-compose down
            echo "LiteLLM proxy stopped"
          '';
        };

        ".local/bin/litellm-logs" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            cd ~/.config/ai-orchestration/litellm
            docker-compose logs -f litellm-proxy
          '';
        };
      };
    };

    # LiteLLM config - uses generic model names, not provider-specific
    xdg.configFile."ai-orchestration/litellm/config.yaml".text = ''
      # LiteLLM Configuration for AI Orchestration
      # Model names are generic (research-model, coding-model) for flexibility
      # Actual provider models defined here can be changed without updating callers

      model_list:
        # Research model - currently Gemini 3 Pro (1M context, strong reasoning)
        - model_name: research-model
          litellm_params:
            model: gemini/gemini-3-pro
            # API key injected at runtime via wrapper

        # Coding model - currently Claude Sonnet 4.5
        - model_name: coding-model
          litellm_params:
            model: anthropic/claude-sonnet-4-5-20251101

        # Fast model - currently Claude Sonnet 4.5
        - model_name: fast-model
          litellm_params:
            model: anthropic/claude-sonnet-4-5-20251101

        # Architecture model - Claude Opus 4.5 for complex reasoning
        - model_name: architecture-model
          litellm_params:
            model: anthropic/claude-opus-4-5-20251101

        # Local research - Qwen3-next 80B
        - model_name: local-research
          litellm_params:
            model: ollama/qwen3-next:80b
            api_base: ${parentCfg.ollamaHost}

        # Local coding - Qwen3-coder 30B
        - model_name: local-coding
          litellm_params:
            model: ollama/qwen3-coder:30b
            api_base: ${parentCfg.ollamaHost}

        # Local reasoning - DeepSeek-R1 70B
        - model_name: local-reasoning
          litellm_params:
            model: ollama/deepseek-r1:70b-llama-distill-q8_0
            api_base: ${parentCfg.ollamaHost}

      litellm_settings:
        fallback_on_errors:
          - ContextWindowExceededError
          - RateLimitError
          - AuthenticationError
          - ServiceUnavailableError
        enable_logging: true
        log_path: ${orbstackDir}/logs
        log_level: INFO
        max_budget: ${toString cfg.maxBudgetUSD}
        budget_reset_window: daily
        request_timeout: 300
        api_timeout: 120

      router_settings:
        routing_strategy: least-busy
        fallbacks:
          - model: coding-model
            fallback: local-coding
          - model: research-model
            fallback: local-research
    '';

    # Docker Compose for OrbStack
    xdg.configFile."ai-orchestration/litellm/docker-compose.yml".text = ''
      services:
        litellm-proxy:
          image: ghcr.io/berriai/litellm:main-latest
          container_name: litellm-proxy
          ports:
            - "${toString cfg.port}:4000"
          volumes:
            - ./config.yaml:/app/config.yaml:ro
            - ./logs:/app/logs
          command: ["--config", "/app/config.yaml"]
          environment:
            # Secrets will be injected by wrapper script
            - OLLAMA_API_BASE=${parentCfg.ollamaHost}
          restart: unless-stopped
          extra_hosts:
            - "host.docker.internal:host-gateway"

      networks:
        default:
          name: ai-orchestration
    '';
  };
}
