# Agent OS Home-Manager Module
#
# Global installation of Agent OS for spec-driven AI development.
# Commands and agents are installed globally to ~/.claude/ and available
# in ALL projects without per-project setup.
#
# Strategy: DRY - One installation, universal access
# - Commands symlinked to ~/.claude/commands/
# - Agents symlinked to ~/.claude/agents/
# - Skills (from standards) symlinked to ~/.claude/skills/ (optional)
# - Workflows exposed at ~/agent-os/workflows (optional)
# - Config stored in ~/agent-os/config.yml
#
# Usage:
#   programs.agent-os = {
#     enable = true;
#     claudeCodeCommands = true;
#     useClaudeCodeSubagents = true;
#     standardsAsClaudeCodeSkills = true;  # Optional: expose standards as skills
#     exposeWorkflows = true;              # Optional: expose workflow templates
#   };
#
# Reference: https://buildermethods.com/agent-os

{ config, lib, agent-os, ... }:

let
  cfg = config.programs.agent-os;

  # Generate config.yml using lib.generators.toYAML for robustness
  configYaml = lib.generators.toYAML {} {
    defaults = {
      profile = cfg.profile;
      claude_code_commands = cfg.claudeCodeCommands;
      use_claude_code_subagents = cfg.useClaudeCodeSubagents;
      standards_as_claude_code_skills = cfg.standardsAsClaudeCodeSkills;
      agent_os_commands = cfg.agentOsCommands;
    };
  };

  # Agent OS commands to install globally
  # These are the 7 core Agent OS slash commands
  agentOsCommands = [
    "create-tasks"
    "implement-tasks"
    "improve-skills"
    "orchestrate-tasks"
    "plan-product"
    "shape-spec"
    "write-spec"
  ];

  # Agent OS agents to install globally
  # These are the 8 specialized subagents for autonomous task delegation
  agentOsAgents = [
    "implementation-verifier"
    "implementer"
    "product-planner"
    "spec-initializer"
    "spec-shaper"
    "spec-verifier"
    "spec-writer"
    "tasks-list-creator"
  ];

  # Generate command symlinks to ~/.claude/commands/
  # Commands are in profiles/default/commands/{name}/{name}.md
  # NOTE: This assumes the agent-os v1.x directory structure. If agent-os changes its structure,
  # this symlink logic will need to be updated.
  commandFiles = builtins.listToAttrs (map (name: {
    name = ".claude/commands/${name}.md";
    value.source = "${agent-os}/profiles/default/commands/${name}/${name}.md";
  }) agentOsCommands);

  # Generate agent symlinks to ~/.claude/agents/
  # Agents are in profiles/default/agents/{name}.md
  agentFiles = builtins.listToAttrs (map (name: {
    name = ".claude/agents/${name}.md";
    value.source = "${agent-os}/profiles/default/agents/${name}.md";
  }) agentOsAgents);

  # Generate skill symlinks from standards directories
  # Standards are in profiles/default/standards/{category}/*.md
  # Each file becomes: ~/.claude/skills/{category}-{filename}.md
  # NOTE: This uses builtins.readDir which reads at evaluation time
  # If agent-os changes its standards structure, this logic needs updating
  standardsCategories = ["backend" "frontend" "global" "testing"];
  
  # Helper function to generate skill files for a single category
  # Returns attrset of { ".claude/skills/{category}-{file}.md" = { source = ...; }; }
  generateSkillsForCategory = category:
    let
      standardsPath = "${agent-os}/profiles/default/standards/${category}";
      # Try to read directory, return empty set if it doesn't exist
      filesInCategory = 
        if builtins.pathExists standardsPath
        then builtins.attrNames (builtins.readDir standardsPath)
        else [];
      # Filter to only .md files
      mdFiles = builtins.filter (name: lib.hasSuffix ".md" name) filesInCategory;
    in
      builtins.listToAttrs (map (filename: {
        name = ".claude/skills/${category}-${filename}";
        value.source = "${standardsPath}/${filename}";
      }) mdFiles);

  # Combine all categories into a single attrset
  skillFiles = builtins.foldl' (acc: cat: acc // (generateSkillsForCategory cat)) {} standardsCategories;

  # Skill template symlink
  skillTemplateFile = {
    ".claude/skills/TEMPLATE.md".source = "${agent-os}/profiles/default/claude-code-skill-template.md";
  };

  # Workflow symlinks - expose workflows directory
  # Workflows are in profiles/default/workflows/
  # Symlink to ~/agent-os/workflows for easy reference
  workflowFiles = {
    "agent-os/workflows".source = "${agent-os}/profiles/default/workflows";
  };

in {
  options.programs.agent-os = {
    enable = lib.mkEnableOption "Agent OS integration for spec-driven AI development";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Agent OS profile to use. Custom profiles can be created manually.";
    };

    claudeCodeCommands = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install Claude Code slash commands for Agent OS globally.
        Provides /shape-spec, /write-spec, /create-tasks, /implement-tasks, etc.
        Available in all projects without per-project setup.
      '';
    };

    useClaudeCodeSubagents = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow Claude Code commands to delegate tasks to specialized subagents.
        More autonomous but higher token usage. Requires claudeCodeCommands.
      '';
    };

    standardsAsClaudeCodeSkills = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Convert standards to Claude Code Skills in .claude/skills/.
        Claude applies them automatically based on context. Requires claudeCodeCommands.
      '';
    };

    agentOsCommands = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Generate Agent OS commands in agent-os/commands/ for other AI tools.
        Use this for Cursor, Windsurf, Codex, Gemini, etc.
      '';
    };

    exposeWorkflows = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Expose Agent OS workflows directory at ~/agent-os/workflows.
        Provides structured multi-step processes for implementation, planning, and specification.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Enforce option dependencies
    assertions = [
      {
        assertion = cfg.useClaudeCodeSubagents -> cfg.claudeCodeCommands;
        message = "programs.agent-os.useClaudeCodeSubagents requires programs.agent-os.claudeCodeCommands to be enabled.";
      }
      {
        assertion = cfg.standardsAsClaudeCodeSkills -> cfg.claudeCodeCommands;
        message = "programs.agent-os.standardsAsClaudeCodeSkills requires programs.agent-os.claudeCodeCommands to be enabled.";
      }
    ];

    home.file = {
      # Nix-generated configuration
      "agent-os/config.yml".text = ''
        # Agent OS Configuration
        # Generated by Nix - do not edit manually
        # To change settings, update programs.agent-os in your Nix configuration
      '' + configYaml;

      # Reference documentation
      "agent-os/CHANGELOG.md".source = "${agent-os}/CHANGELOG.md";

      # Profile template for reference (users can customize)
      "agent-os/profiles/default".source = "${agent-os}/profiles/default";
    }
    # Global command symlinks (when claudeCodeCommands enabled)
    // lib.optionalAttrs cfg.claudeCodeCommands commandFiles
    # Global agent symlinks (when subagents enabled)
    // lib.optionalAttrs cfg.useClaudeCodeSubagents agentFiles
    # Standards as skills symlinks (when standardsAsClaudeCodeSkills enabled)
    // lib.optionalAttrs cfg.standardsAsClaudeCodeSkills (skillFiles // skillTemplateFile)
    # Workflows symlink (when exposeWorkflows enabled)
    // lib.optionalAttrs cfg.exposeWorkflows workflowFiles;
  };
}
