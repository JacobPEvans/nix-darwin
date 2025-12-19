# AI CLI Permission Formatters
#
# Transforms tool-agnostic command definitions into tool-specific formats.
# Each tool has different permission syntax requirements.
#
# FORMATS:
# - Claude Code: Bash(cmd:*) for shell, Read(**) for file tools
# - Gemini CLI: ShellTool(cmd) for shell, ReadFileTool for file tools
# - Copilot CLI: shell(cmd) patterns for runtime flags
# - OpenCode: TBD (placeholder for future)

{ lib }:

let
  # Flatten nested attribute sets into a list of commands
  # Handles both lists and nested attrsets
  flattenCommands =
    attrs:
    lib.flatten (
      lib.mapAttrsToList (
        _name: value:
        if builtins.isList value then
          value
        else if builtins.isAttrs value then
          flattenCommands value
        else
          [ ]
      ) attrs
    );

in
{
  # ============================================================================
  # CLAUDE CODE FORMATTER
  # ============================================================================
  # Format: Bash(cmd:*) for shell commands
  # The :* suffix is Claude-specific wildcard syntax: it matches "cmd:" followed by any arguments

  claude = {
    # Format a single shell command for Claude
    formatShellCommand = cmd: "Bash(${cmd}:*)";

    # Format a list of shell commands
    formatShellCommands = cmds: map (cmd: "Bash(${cmd}:*)") cmds;

    # Format all allowed commands from permissions
    formatAllowed =
      permissions:
      let
        allCommands = flattenCommands permissions.allow;
      in
      map (cmd: "Bash(${cmd}:*)") allCommands;

    # Format all denied commands
    formatDenied =
      permissions:
      let
        allCommands = flattenCommands permissions.deny;
      in
      map (cmd: "Bash(${cmd}:*)") allCommands;

    # Get tool-specific permissions (non-shell)
    getToolPermissions = permissions: permissions.toolSpecific.claude.core or [ ];
  };

  # ============================================================================
  # GEMINI CLI FORMATTER
  # ============================================================================
  # Format: ShellTool(cmd) for shell commands
  # No wildcard suffix - exact command match or prefix match

  gemini = {
    # Format a single shell command for Gemini
    formatShellCommand = cmd: "ShellTool(${cmd})";

    # Format a list of shell commands
    formatShellCommands = cmds: map (cmd: "ShellTool(${cmd})") cmds;

    # Format all allowed commands (coreTools)
    formatCoreTools =
      permissions:
      let
        allCommands = flattenCommands permissions.allow;
        shellTools = map (cmd: "ShellTool(${cmd})") allCommands;
        coreTools = permissions.toolSpecific.gemini.core or [ ];
      in
      coreTools ++ shellTools;

    # Format all denied commands (excludeTools)
    formatExcludeTools =
      permissions:
      let
        allCommands = flattenCommands permissions.deny;
      in
      map (cmd: "ShellTool(${cmd})") allCommands;

    # Get tool-specific permissions (non-shell)
    getToolPermissions = permissions: permissions.toolSpecific.gemini.core or [ ];
  };

  # ============================================================================
  # COPILOT CLI FORMATTER
  # ============================================================================
  # Format: shell(cmd) patterns for --allow-tool and --deny-tool flags
  # Note: Copilot permissions are primarily directory-based in config

  copilot = {
    # Format a single shell command for Copilot
    formatShellCommand = cmd: "shell(${cmd})";

    # Format a list of shell commands
    formatShellCommands = cmds: map (cmd: "shell(${cmd})") cmds;

    # Get trusted directories
    getTrustedFolders =
      permissions:
      let
        dirs = permissions.directories or { };
      in
      (dirs.home or [ ]) ++ (dirs.development or [ ]) ++ (dirs.config or [ ]);

    # Format denied commands for --deny-tool flags
    formatDenyFlags =
      permissions:
      let
        allCommands = flattenCommands permissions.deny;
      in
      map (cmd: "shell(${cmd})") allCommands;
  };

  # ============================================================================
  # OPENCODE FORMATTER (Placeholder)
  # ============================================================================
  # Format: TBD - will be implemented when OpenCode integration is added

  opencode = {
    # Placeholder - format will be determined during OpenCode integration
    formatShellCommand = cmd: cmd;
    formatShellCommands = cmds: cmds;
  };

  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================

  utils = {
    # Flatten commands from nested permission structure
    inherit flattenCommands;

    # Count total commands in a permission set
    countCommands = permissions: builtins.length (flattenCommands permissions);

    # Get all categories from permissions
    getCategories = permissions: builtins.attrNames permissions;
  };
}
