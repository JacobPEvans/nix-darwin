# Modern CLI Tools
#
# Popular CLI alternatives that enhance productivity.
# These are useful for any user, not just developers.

{ pkgs }:

with pkgs; [
  bat       # Better cat with syntax highlighting
  eza       # Modern ls replacement with git integration
  fd        # Faster, user-friendly find alternative
  fzf       # Fuzzy finder for interactive selection
  jq        # JSON parsing for config files and API responses
  ripgrep   # Fast grep alternative (rg command)
  tree      # Directory tree visualization
]
