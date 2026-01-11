# Powerline Theme - Claude Code Statusline
#
# Multi-line statusline powered by @owloops/claude-powerline.
# Uses bunx at runtime for simplicity - no build-time hashes to maintain.
#
# Repository: https://github.com/Owloops/claude-powerline
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.claudeStatusline;

  # JSON config written manually to preserve segment order
  # (Nix attrsets sort alphabetically when converted via builtins.toJSON)
  configJson = ''
    {
      "theme": "rose-pine",
      "style": "capsule",
      "charset": "unicode",
      "autoWrap": false,
      "display": {
        "lines": [
          {
            "segments": {
              "model": { "enabled": true },
              "context": { "enabled": true, "showPercentageOnly": true }
            }
          },
          {
            "segments": {
              "git": {
                "enabled": true,
                "showRepoName": true,
                "showBranch": true,
                "showBehind": true,
                "showClean": true,
                "showChanges": true,
                "showSha": false,
                "showUpstream": false,
                "showWorktree": false,
                "showStash": false
              },
              "directory": { "enabled": false }
            }
          },
          {
            "segments": {
              "session": { "enabled": true, "type": "tokens" },
              "today": { "enabled": true, "type": "breakdown" },
              "block": { "enabled": false },
              "metrics": { "enabled": false },
              "version": { "enabled": false }
            }
          }
        ]
      },
      "budget": {
        "session": { "amount": 10.0, "type": "tokens", "warningThreshold": 80 },
        "today": { "amount": 25.0, "type": "tokens", "warningThreshold": 80 }
      }
    }
  '';

  configFile = pkgs.writeText "claude-powerline.json" configJson;

in
{
  config = lib.mkIf cfg.enable {
    programs.claude.statusLine = {
      enable = true;
      script = ''
        #!/usr/bin/env bash
        # Claude Powerline statusline
        # Uses bunx for runtime execution (no build-time hash maintenance)
        exec ${pkgs.bun}/bin/bunx @owloops/claude-powerline --config=${configFile} "$@"
      '';
    };
  };
}
