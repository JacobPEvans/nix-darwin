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

    # Format all allowed commands from permissions (shell + tool-specific)
    formatAllowed =
      permissions:
      let
        allCommands = flattenCommands permissions.allow;
        shellPermissions = map (cmd: "Bash(${cmd}:*)") allCommands;
        claudePerms = permissions.toolSpecific.claude or { };
        toolPermissions =
          (claudePerms.builtin or [ ]) ++ (claudePerms.webFetch or [ ]) ++ (claudePerms.read or [ ]);
      in
      toolPermissions ++ shellPermissions;

    # Format all denied commands (shell + tool-specific)
    formatDenied =
      permissions:
      let
        allCommands = flattenCommands permissions.deny;
        shellDenied = map (cmd: "Bash(${cmd}:*)") allCommands;
        claudePerms = permissions.toolSpecific.claude or { };
        toolDenied = claudePerms.denyRead or [ ];
      in
      toolDenied ++ shellDenied;

    # Get all tool-specific permissions (non-shell)
    getToolPermissions =
      permissions:
      let
        claudePerms = permissions.toolSpecific.claude or { };
      in
      (claudePerms.builtin or [ ]) ++ (claudePerms.webFetch or [ ]) ++ (claudePerms.read or [ ]);

    # Get tool-specific deny permissions
    getDenyPermissions =
      permissions:
      let
        claudePerms = permissions.toolSpecific.claude or { };
      in
      claudePerms.denyRead or [ ];
  };

  # ============================================================================
  # GEMINI CLI FORMATTER
  # ============================================================================
  # Format: ShellTool(cmd) for shell commands
  # No wildcard suffix - exact command match or prefix match
  #
  # CRITICAL - tools.allowed vs tools.core in settings.json:
  # =========================================================
  # Per the official Gemini CLI schema:
  # - tools.allowed = "Tool names that bypass the confirmation dialog" (AUTO-APPROVE)
  # - tools.core = "Allowlist to RESTRICT built-in tools to a specific set" (LIMITS usage!)
  #
  # This formatter provides formatAllowedTools for the "allowed" key.
  # NEVER use formatAllowedTools output for "core" - that would break permissions!
  # Schema: https://github.com/google-gemini/gemini-cli/blob/main/schemas/settings.schema.json

  gemini = {
    # Format a single shell command for Gemini
    formatShellCommand = cmd: "ShellTool(${cmd})";

    # Format a list of shell commands
    formatShellCommands = cmds: map (cmd: "ShellTool(${cmd})") cmds;

    # Format all auto-approved commands for tools.allowed (NOT tools.core!)
    # Output goes to settings.json "tools.allowed" to bypass confirmation dialog
    formatAllowedTools =
      permissions:
      let
        allCommands = flattenCommands permissions.allow;
        shellTools = map (cmd: "ShellTool(${cmd})") allCommands;
        # Built-in Gemini tools (ReadFileTool, etc.) from permissions.nix
        builtinTools = permissions.toolSpecific.gemini.builtin or [ ];
      in
      builtinTools ++ shellTools;

    # Format all denied commands (excludeTools)
    formatExcludeTools =
      permissions:
      let
        allCommands = flattenCommands permissions.deny;
      in
      map (cmd: "ShellTool(${cmd})") allCommands;

    # Get tool-specific permissions (non-shell)
    getToolPermissions = permissions: permissions.toolSpecific.gemini.builtin or [ ];
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
