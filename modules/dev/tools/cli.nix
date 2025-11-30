# Development CLI Tools
#
# Miscellaneous CLI tools useful for development.

{ pkgs }:

with pkgs; [
  gemini-cli  # Google's Gemini CLI for AI assistance
  htop        # Interactive process viewer (better top)
  mas         # Mac App Store CLI (search/install apps)
  ncdu        # NCurses disk usage analyzer
  tldr        # Simplified, community-driven man pages
]
