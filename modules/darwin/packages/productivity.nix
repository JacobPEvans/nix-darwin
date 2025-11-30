# Productivity Applications
#
# GUI applications for daily productivity.
# These are user-facing apps, not development tools.

{ pkgs }:

with pkgs; [
  bitwarden-desktop   # Password manager desktop app
  google-chrome       # Web browser (Nix-managed, no extensions)
  obsidian            # Knowledge base / note-taking (Markdown)
  raycast             # Productivity launcher (replaces Spotlight)
  vscode              # Visual Studio Code editor
  zoom-us             # Video conferencing
]
