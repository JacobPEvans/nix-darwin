# AI Orchestration - Anthropic Skills Module
#
# Manages Anthropic Skills and Plugins via Nix:
# - anthropics/skills marketplace
# - anthropics/claude-plugins-official
# - Custom skills for multi-model routing
#
# All plugins installed declaratively via Nix, not manually.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ai-orchestration.skills;

in
{
  options.services.ai-orchestration.skills = {
    enable = lib.mkEnableOption "Anthropic Skills and Plugins";

    enableDocumentSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable document creation skills (docx, xlsx, pptx, pdf)";
    };

    enableExampleSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable example skills from Anthropic";
    };

    customSkillsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.claude/skills";
      description = "Directory for custom skills";
    };
  };

  config = lib.mkIf cfg.enable {
    # Register Anthropic marketplaces via Claude's extraKnownMarketplaces
    # This integrates with the existing claude module
    programs.claude.extraKnownMarketplaces = {
      "anthropics/skills" = {
        source = {
          type = "git";
          url = "https://github.com/anthropics/skills";
        };
      };
      "anthropics/claude-plugins-official" = {
        source = {
          type = "git";
          url = "https://github.com/anthropics/claude-plugins-official";
        };
      };
    };

    # Enable specific plugins
    programs.claude.enabledPlugins = lib.mkMerge [
      (lib.mkIf cfg.enableDocumentSkills {
        "document-skills@anthropic-agent-skills" = true;
      })
      (lib.mkIf cfg.enableExampleSkills {
        "example-skills@anthropic-agent-skills" = true;
      })
    ];

    # Custom multi-model router skill
    home.file."${cfg.customSkillsDir}/multi-model-router/SKILL.md".text = ''
      ---
      name: multi-model-router
      description: Routes tasks to optimal model based on task type. Uses current best models.
      ---

      # Multi-Model Router Skill

      Routes tasks to the most appropriate model without hardcoding model names.

      ## Configuration

      Model selection is defined in: `~/.config/ai-orchestration/model-config.yaml`

      ## Routing Logic

      1. Detect task type from prompt (research, coding, review, planning)
      2. Look up current best model for task type
      3. Use PAL MCP to delegate if available
      4. Return synthesized results

      ## Task Type Detection

      | Task Type | Keywords |
      |-----------|----------|
      | Research | research, investigate, survey, compare options |
      | Coding | implement, write code, fix bug, refactor |
      | Review | review, audit, check, validate |
      | Planning | plan, design, architect, roadmap |

      ## Local-Only Support

      Set `AI_ORCHESTRATION_LOCAL_ONLY=true` to use only Ollama models.

      ## Current Model Assignments (December 2025)

      - **Research**: Gemini 3 Pro (1M context, strong reasoning)
      - **Coding**: Claude Sonnet 4.5 (fast, capable)
      - **Architecture**: Claude Opus 4.5 (complex reasoning, planning)
      - **Review**: Multi-model consensus via PAL
      - **Planning**: Claude Opus 4.5 (architectural decisions)
      - **Local Research**: qwen3-next:80b
      - **Local Coding**: qwen3-coder:30b

      These assignments should be reviewed monthly as new models are released.
    '';

    # Model configuration file
    xdg.configFile."ai-orchestration/model-config.yaml".text = ''
      # Model Configuration for AI Orchestration
      # Update this file when better models become available
      # Last updated: December 2025

      cloud_models:
        research: gemini-3-pro
        coding: claude-sonnet-4-5
        architecture: claude-opus-4-5
        fast: claude-sonnet-4-5
        review: consensus  # Uses PAL multi-model consensus

      local_models:
        research: qwen3-next:80b
        coding: qwen3-coder:30b
        reasoning: deepseek-r1:70b

      # Model metadata for freshness tracking
      model_info:
        gemini-3-pro:
          release_date: "2025-12-01"
          context_window: 1000000
          strengths: ["research", "reasoning", "large documents"]

        claude-sonnet-4-5:
          release_date: "2025-10-22"
          context_window: 200000
          strengths: ["coding", "fast responses", "general tasks"]

        claude-opus-4-5:
          release_date: "2025-11-24"
          context_window: 200000
          strengths: ["architecture", "complex reasoning", "planning", "autonomous operation"]

        qwen3-next:80b:
          release_date: "2025-12-01"
          strengths: ["local research", "reasoning"]

        qwen3-coder:30b:
          release_date: "2025-11-15"
          strengths: ["local coding", "fast"]
    '';
  };
}
