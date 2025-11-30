# Common Linters
#
# Linting tools used across most projects.
# Support pre-commit hooks and CI/CD pipelines.

{ pkgs }:

with pkgs; [
  # Shell
  shellcheck          # Shell script static analysis (POSIX, bash)
  shfmt               # Shell script formatter

  # Documentation
  markdownlint-cli2   # Markdown linter (README, docs)

  # CI/CD
  actionlint          # GitHub Actions workflow linter

  # Nix
  nixfmt-classic      # Nix code formatter
]
