# Advanced Theme - Claude Code Statusline
#
# DEPRECATED: The upstream claude-code-statusline repository (github:rz1989s/claude-code-statusline)
# is no longer available (404). This theme is disabled until an alternative is found.
#
# Use the "powerline" theme instead, which uses github:Owloops/claude-powerline.
#
# Original features (when working):
# - System information display (CPU, memory, disk)
# - 18+ customizable color themes (gruvbox, nord, dracula, etc.)
# - Extended git information
# - Performance metrics
# - Context-aware segments
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.claudeStatusline;
in
{
  config = lib.mkIf (cfg.enable && cfg.theme == "advanced") {
    # Fail with helpful message - the upstream repo is 404
    assertions = [
      {
        assertion = false;
        message = ''
          The "advanced" statusline theme is currently unavailable.

          The upstream repository (github:rz1989s/claude-code-statusline) has been deleted.
          Please use the "powerline" theme instead:

            programs.claudeStatusline = {
              enable = true;
              theme = "powerline";
              powerline.style = "dracula";  # or: default, minimal, rainbow, gruvbox, nord
            };

          The powerline theme uses github:Owloops/claude-powerline which is actively maintained.
        '';
      }
    ];
  };
}
