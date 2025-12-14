# AI Orchestration - Model Benchmarking Module
#
# Uses existing tools (not custom scripts):
# - llm-benchmark (PyPI): CLI tool for Ollama throughput benchmarking
# - Open WebUI: Arena mode for blind A/B model comparison
#
# All tools are installed via Nix.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai-orchestration.benchmark;
  parentCfg = config.services.ai-orchestration;

  # Python environment with llm-benchmark
  pythonWithBenchmark = pkgs.python3.withPackages (ps: [
    ps.requests
    ps.pyyaml
    ps.rich
  ]);

in
{
  options.services.ai-orchestration.benchmark = {
    enable = lib.mkEnableOption "Model benchmarking tools";

    enableOpenWebUI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Open WebUI for arena-style model comparison";
    };

    openWebUIPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Open WebUI";
    };

    openWebUIDataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/open-webui";
      description = "Data directory for Open WebUI";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Open WebUI for arena comparison (already in nixpkgs)
      pkgs.open-webui

      # Python for llm-benchmark (install via pipx at runtime)
      pythonWithBenchmark
      pkgs.pipx
    ];

    # Open WebUI Docker Compose config for OrbStack
    xdg.configFile."ai-orchestration/open-webui/docker-compose.yml" = lib.mkIf cfg.enableOpenWebUI {
      text = ''
        # Open WebUI Docker Compose for OrbStack
        # Start with: docker-compose up -d
        # Access at: http://localhost:${toString cfg.openWebUIPort}
        services:
          open-webui:
            image: ghcr.io/open-webui/open-webui:main
            container_name: open-webui
            ports:
              - "${toString cfg.openWebUIPort}:8080"
            environment:
              - OLLAMA_BASE_URL=${parentCfg.ollamaHost}
              - ENABLE_SIGNUP=false
              - ENABLE_ARENA=true
              - WEBUI_AUTH=true
            volumes:
              - ${cfg.openWebUIDataDir}:/app/backend/data
            restart: unless-stopped
            extra_hosts:
              - "host.docker.internal:host-gateway"

        networks:
          default:
            name: ai-orchestration
      '';
    };

    # Helper scripts
    home.file.".local/bin/ai-benchmark" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Run llm-benchmark via pipx
        set -euo pipefail

        if ! command -v llm_benchmark &> /dev/null; then
          echo "Installing llm-benchmark via pipx..." >&2
          pipx install llm-benchmark
        fi

        llm_benchmark "$@"
      '';
    };

    home.file.".local/bin/ai-arena-start" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Start Open WebUI arena for model comparison
        set -euo pipefail

        cd ~/.config/ai-orchestration/open-webui
        docker-compose up -d
        echo "Open WebUI started at http://localhost:${toString cfg.openWebUIPort}"
        echo "Arena mode enabled for blind model comparison"
      '';
    };

    home.file.".local/bin/ai-arena-stop" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Stop Open WebUI arena
        set -euo pipefail

        cd ~/.config/ai-orchestration/open-webui
        docker-compose down
        echo "Open WebUI stopped"
      '';
    };
  };
}
