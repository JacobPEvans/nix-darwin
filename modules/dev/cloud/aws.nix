# AWS Cloud Tools
#
# AWS CLI and credential management tools for cloud infrastructure work.

{ pkgs }:

with pkgs; [
  awscli2     # AWS CLI v2 - unified tool to manage AWS services
  aws-vault   # Secure AWS credential storage (uses OS keychain)
]
