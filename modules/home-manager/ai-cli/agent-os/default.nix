# Agent OS Home-Manager Module
#
# Global installation of Agent OS for spec-driven AI development.
# Commands and agents are installed globally to ~/.claude/ and available
# in ALL projects without per-project setup.
#
# Strategy: DRY - One installation, universal access
# - Commands symlinked to ~/.claude/commands/
# - Agents symlinked to ~/.claude/agents/
# - Skills (from standards) symlinked to ~/.claude/skills/
# - Workflows exposed at ~/agent-os/workflows
# - Config stored in ~/agent-os/config.yml
#
# Usage:
#   programs.agent-os = {
#     enable = true;
#     claudeCodeCommands = true;
#     useClaudeCodeSubagents = true;
#     standardsAsClaudeCodeSkills = true;
#     exposeWorkflows = true;
#   };
#
# Reference: https://buildermethods.com/agent-os

{
  config,
  lib,
  agent-os,
  ...
}:

let
  cfg = config.programs.agent-os;

  # Generate config.yml using lib.generators.toYAML for robustness
  configYaml = lib.generators.toYAML { } {
    defaults = {
      inherit (cfg) profile;
      claude_code_commands = cfg.claudeCodeCommands;
      use_claude_code_subagents = cfg.useClaudeCodeSubagents;
      standards_as_claude_code_skills = cfg.standardsAsClaudeCodeSkills;
      expose_workflows = cfg.exposeWorkflows;
      agent_os_commands = cfg.agentOsCommands;
    };
  };

  # Agent OS command structure:
  # Most commands have single-agent/ and multi-agent/ subdirectories
  # A few commands (improve-skills, orchestrate-tasks) are directly in their folder
  #
  # Commands with subdirectory structure:
  commandsWithSubdirs = [
    "create-tasks"
    "implement-tasks"
    "plan-product"
    "shape-spec"
    "write-spec"
  ];

  # Commands without subdirectory structure (file is directly in command folder):
  commandsWithoutSubdirs = [
    "improve-skills"
    "orchestrate-tasks"
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

  # Determine which subdir to use based on useClaudeCodeSubagents setting
  # multi-agent mode uses specialized subagents, single-agent mode is self-contained
  commandSubdir = if cfg.useClaudeCodeSubagents then "multi-agent" else "single-agent";

  # Generate command symlinks for commands WITH subdirectory structure
  # Path: profiles/default/commands/{name}/{subdir}/{name}.md
  commandFilesWithSubdirs = builtins.listToAttrs (
    map (name: {
      name = ".claude/commands/${name}.md";
      value.source = "${agent-os}/profiles/default/commands/${name}/${commandSubdir}/${name}.md";
    }) commandsWithSubdirs
  );

  # Generate command symlinks for commands WITHOUT subdirectory structure
  # Path: profiles/default/commands/{name}/{name}.md
  commandFilesWithoutSubdirs = builtins.listToAttrs (
    map (name: {
      name = ".claude/commands/${name}.md";
      value.source = "${agent-os}/profiles/default/commands/${name}/${name}.md";
    }) commandsWithoutSubdirs
  );

  # Combined command files
  commandFiles = commandFilesWithSubdirs // commandFilesWithoutSubdirs;

  # Generate agent symlinks to ~/.claude/agents/
  # Agents are in profiles/default/agents/{name}.md
  agentFiles = builtins.listToAttrs (
    map (name: {
      name = ".claude/agents/${name}.md";
      value.source = "${agent-os}/profiles/default/agents/${name}.md";
    }) agentOsAgents
  );

  # Generate skill symlinks from standards directories
  # Standards are in profiles/default/standards/{category}/*.md
  # Each file becomes: ~/.claude/skills/{category}-{filename}.md
  #
  # Evaluation Strategy:
  # - builtins.readDir runs at Nix evaluation time (during build)
  # - If agent-os structure changes, rebuild required to pick up changes
  # - Missing directories gracefully return empty sets (no build failure)
  # - This is intentional: ensures skills match the agent-os version in flake.lock
  standardsCategories = [
    "backend"
    "frontend"
    "global"
    "testing"
  ];

  # Helper function to generate skill files for a single category
  # Returns attrset of { ".claude/skills/{category}-{file}.md" = { source = ...; }; }
  generateSkillsForCategory =
    category:
    let
      standardsPath = "${agent-os}/profiles/default/standards/${category}";
      # Graceful fallback: if directory doesn't exist, return empty attrset
      # This handles cases where agent-os repo structure changes or categories are removed
      dirContents = if builtins.pathExists standardsPath then builtins.readDir standardsPath else { };
      filesInCategory = builtins.attrNames dirContents;
      # Filter to only .md files
      mdFiles = builtins.filter (name: lib.hasSuffix ".md" name) filesInCategory;
    in
    builtins.listToAttrs (
      map (filename: {
        name = ".claude/skills/${category}-${filename}";
        value.source = "${standardsPath}/${filename}";
      }) mdFiles
    );

  # Combine all categories into a single attrset
  skillFiles = builtins.foldl' (acc: attrs: acc // attrs) { } (
    map generateSkillsForCategory standardsCategories
  );

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

in
{
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
        Use multi-agent command variants that delegate tasks to specialized subagents.
        When true: uses multi-agent/ command versions (higher autonomy, more tokens)
        When false: uses single-agent/ command versions (self-contained, fewer tokens)
        Also controls whether agent symlinks are installed.
      '';
    };

    standardsAsClaudeCodeSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install standards as Claude Code Skills in ~/.claude/skills/.
        Skills are automatically applied by Claude based on context.
        Includes backend, frontend, global, and testing standards.
      '';
    };

    exposeWorkflows = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Expose Agent OS workflows directory at ~/agent-os/workflows.
        Provides structured multi-step processes for implementation, planning, and specification.
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
  };

  config = lib.mkIf cfg.enable {
    # Enforce option dependencies
    assertions = [
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
      ''
      + configYaml;

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
