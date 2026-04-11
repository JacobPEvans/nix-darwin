# Custom-auth launchers for `claude` (Claude Code).
# Sibling of gh-token-switching.zsh; sourced from home.nix initContent.
#
# Provides:
#   av-claude <profile> [claude-args...]   aws-vault exec <profile> -- claude ...
#   gh-claude-restricted [claude-args...]  claude with GITHUB_TOKEN from the RESTRICTED tier
#   gh-claude-private    [claude-args...]  claude with GITHUB_TOKEN from the PRIVATE tier
#   gh-claude-admin      [claude-args...]  claude with GITHUB_TOKEN from the ADMIN tier
#
# Each gh-claude-* wrapper runs its underlying gh-* function (defined in
# gh-token-switching.zsh) inside a subshell, so the GITHUB_TOKEN and
# GH_ENV_MODE exports those functions produce do NOT leak into the parent
# shell after claude exits. This preserves the shell's default least-privilege
# tier. The tier names (RESTRICTED / PRIVATE / ADMIN) correspond to the macOS
# Keychain service names GH_PAT_RESTRICTED / GH_PAT_PRIVATE / GH_PAT_ADMIN
# from which the underlying gh-* functions read the token.

av-claude() {
  if (( $# == 0 )); then
    echo "usage: av-claude <aws-vault-profile> [claude-args...]" >&2
    echo "       profiles: see ~/.aws/config" >&2
    echo "       e.g.  av-claude terraform" >&2
    echo "             av-claude tf-proxmox --resume" >&2
    return 2
  fi
  local profile="$1"
  shift
  aws-vault exec "$profile" -- claude "$@"
}

gh-claude-restricted() { ( gh-restricted >/dev/null && exec claude "$@" ); }
gh-claude-private()    { ( gh-private    >/dev/null && exec claude "$@" ); }
gh-claude-admin()      { ( gh-admin      >/dev/null && exec claude "$@" ); }
