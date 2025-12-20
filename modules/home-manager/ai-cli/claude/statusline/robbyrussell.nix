# Robbyrussell Theme - Claude Code Statusline
#
# DEPRECATED: The upstream claude-code-statusline repository (github:rz1989s/claude-code-statusline)
# is no longer available (404). This theme is disabled until an alternative is found.
#
# Use the "powerline" theme instead, which uses github:Owloops/claude-powerline.
#
# Original features (when working):
# - Lightweight and fast
# - Single-line display optimized for SSH/mobile
# - Git integration
# - Cost tracking via ccusage
{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.claudeStatusline;
in
{
  config = lib.mkIf (cfg.enable && cfg.theme == "robbyrussell") {
    # Fail with helpful message - the upstream repo is 404
    assertions = [
      {
        assertion = false;
        message = ''
          The "robbyrussell" statusline theme is currently unavailable.

          The upstream repository (github:rz1989s/claude-code-statusline) has been deleted.
          Please use the "powerline" theme instead:

            programs.claudeStatusline = {
              enable = true;
              theme = "powerline";
              powerline.style = "minimal";  # or: default, rainbow, gruvbox, dracula, nord
            };

          The powerline theme uses github:Owloops/claude-powerline which is actively maintained.
          Use "minimal" style for a clean, simple look similar to robbyrussell.
        '';
      }
    ];
  };
}
