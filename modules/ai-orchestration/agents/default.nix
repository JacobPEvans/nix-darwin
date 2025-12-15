# AI Orchestration - Agents Module
#
# Defines generic subagents for task delegation:
# - researcher: Research tasks → best research model
# - coder: Coding tasks → best coding model
# - reviewer: Code review → multi-model consensus
#
# Agent names are GENERIC (not model-specific like "gemini-researcher")
# so they remain valid as models change.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ai-orchestration.agents;
  parentCfg = config.services.ai-orchestration;
  agentsDir = "${config.home.homeDirectory}/.claude/agents";

in
{
  options.services.ai-orchestration.agents = {
    enable = lib.mkEnableOption "Generic AI agents for task delegation";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      # Researcher agent - delegates to best research model
      "${agentsDir}/researcher.md".text = ''
        ---
        name: researcher
        description: Research tasks delegated to current best research model
        ---

        # Researcher Agent

        Research specialist using the best available model for research tasks.

        ## Current Model Selection (Update as needed)

        - **Cloud**: ${parentCfg.defaultResearchModel}
        - **Local**: ${parentCfg.localResearchModel}

        ## Capabilities

        - Large document analysis (1M+ token context)
        - Technology surveys and comparisons
        - Architecture exploration
        - Literature review

        ## When This Agent is Called

        Automatically selected when task contains keywords:
        - research, investigate, survey
        - compare options, analyze landscape
        - explore (alternatives|approaches|solutions)

        ## Usage via PAL MCP

        ```
        Use PAL MCP 'chat' tool with model=research-model
        ```

        ## Local-Only Mode

        When AI_ORCHESTRATION_LOCAL_ONLY=true:
        - Routes to ${parentCfg.localResearchModel}
        - No cloud API calls
      '';

      # Coder agent - delegates to best coding model
      "${agentsDir}/coder.md".text = ''
        ---
        name: coder
        description: Coding tasks using current best coding model
        ---

        # Coder Agent

        Coding specialist with automatic tier selection.

        ## Model Tiers

        - **Frontier**: ${parentCfg.defaultCodingModel} (complex tasks)
        - **Fast**: ${parentCfg.defaultFastModel} (standard tasks)
        - **Local**: ${parentCfg.localCodingModel} (private/offline)

        ## Automatic Tier Selection

        | Criteria | Tier |
        |----------|------|
        | 100+ lines or architectural changes | Frontier |
        | Bug fixes, small features | Fast |
        | Private repos or offline | Local |
        | User explicitly requests "frontier" | Frontier |

        ## Capabilities

        - Code generation and completion
        - Bug fixing and debugging
        - Refactoring
        - Test writing
        - Documentation

        ## Override

        Explicitly request: "use frontier model for this" to force best available.
      '';

      # Reviewer agent - uses multi-model consensus
      "${agentsDir}/reviewer.md".text = ''
        ---
        name: reviewer
        description: Code review using multi-model consensus
        ---

        # Reviewer Agent

        Code review specialist using multi-model consensus for thorough analysis.

        ## Approach

        Uses PAL MCP 'consensus' tool to get perspectives from multiple models,
        then synthesizes findings into a unified review.

        ## Review Process

        1. Initial analysis by primary model
        2. Cross-validation by secondary model
        3. Consensus synthesis
        4. Severity classification (critical/major/minor)

        ## Models Used

        - Primary: ${parentCfg.defaultResearchModel} (thorough analysis)
        - Secondary: ${parentCfg.defaultCodingModel} (code expertise)
        - Local fallback: ${parentCfg.localResearchModel}

        ## Output Format

        Reviews follow the standard format:
        - Summary of changes
        - Critical issues (must fix)
        - Major issues (should fix)
        - Minor issues (consider fixing)
        - Positive observations

        ## Usage via PAL MCP

        ```
        Use PAL MCP 'codereview' tool for single-model review
        Use PAL MCP 'consensus' tool for multi-model review
        ```
      '';

      # Planner agent - for architecture and design
      "${agentsDir}/planner.md".text = ''
        ---
        name: planner
        description: Planning and architecture tasks
        ---

        # Planner Agent

        Architecture and design specialist.

        ## Current Model

        - **Cloud**: ${parentCfg.defaultResearchModel} (strong reasoning)
        - **Local**: ${parentCfg.localResearchModel}

        ## Capabilities

        - System architecture design
        - Implementation planning
        - Task breakdown
        - Risk identification
        - Dependency analysis

        ## Usage via PAL MCP

        ```
        Use PAL MCP 'planner' tool
        ```

        ## Output

        Plans include:
        - Step-by-step implementation guide
        - Critical files to modify
        - Dependencies and prerequisites
        - Potential risks and mitigations
      '';

      # Task router Python script
      ".local/bin/ai-route-task" = {
        executable = true;
        text = ''
          #!/usr/bin/env python3
          """Route tasks to appropriate models based on content analysis.

          Usage:
              ai-route-task "your prompt here"
              ai-route-task --local "your prompt here"
          """

          import sys
          import json
          import re
          import os

          ROUTING_PATTERNS = {
              "research": r"(research|investigate|survey|compare options|analyze landscape)",
              "coding": r"(implement|write code|fix bug|refactor|create function)",
              "review": r"(review|audit|check|validate)",
              "planning": r"(plan|design|architect|roadmap)",
          }

          CLOUD_MODELS = {
              "research": "${parentCfg.defaultResearchModel}",
              "coding": "${parentCfg.defaultCodingModel}",
              "review": "consensus",
              "planning": "${parentCfg.defaultResearchModel}",
          }

          LOCAL_MODELS = {
              "research": "${parentCfg.localResearchModel}",
              "coding": "${parentCfg.localCodingModel}",
              "review": "${parentCfg.localResearchModel}",
              "planning": "${parentCfg.localResearchModel}",
          }

          def detect_task_type(prompt: str) -> str:
              prompt_lower = prompt.lower()
              for task_type, pattern in ROUTING_PATTERNS.items():
                  if re.search(pattern, prompt_lower):
                      return task_type
              return "coding"

          def main():
              local_only = "--local" in sys.argv or os.environ.get("AI_ORCHESTRATION_LOCAL_ONLY") == "true"
              args = [a for a in sys.argv[1:] if a != "--local"]
              prompt = " ".join(args) if args else ""

              task_type = detect_task_type(prompt)
              models = LOCAL_MODELS if local_only else CLOUD_MODELS
              model = models.get(task_type, models["coding"])

              print(json.dumps({
                  "task_type": task_type,
                  "recommended_model": model,
                  "local_only": local_only,
                  "agent": task_type if task_type != "coding" else "coder"
              }, indent=2))

          if __name__ == "__main__":
              main()
        '';
      };
    };
  };
}
