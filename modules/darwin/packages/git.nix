# Git & GPG Packages
#
# Git version control and GPG for commit signing.
# GPG is bundled here as its primary purpose is git commit signing.

{ pkgs }:

with pkgs; [
  git     # Version control
  gnupg   # GPG for commit/tag signing
]
