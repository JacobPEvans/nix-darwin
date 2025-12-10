# Claude Code Statusline SSH Detection
#
# Automatically switches between full and mobile statusline configs
# based on whether the session is via SSH or local terminal.
#
# Mobile config: Single-line, minimal (dir + reset timer)
# Full config: Multi-line with all features
#
# Run at shell startup to set Config.toml symlink appropriately.

_claude_statusline_switch() {
  local statusline_dir="$HOME/.claude/statusline"
  local config_link="$statusline_dir/Config.toml"
  local config_full="$statusline_dir/config-full.toml"
  local config_mobile="$statusline_dir/config-mobile.toml"

  # Ensure directory exists
  [[ -d "$statusline_dir" ]] || return 0

  # Determine which config to use
  local target_config
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    # SSH session - use mobile config if available
    if [[ -f "$config_mobile" ]]; then
      target_config="$config_mobile"
    else
      target_config="$config_full"
    fi
  else
    # Local session - use full config
    target_config="$config_full"
  fi

  # Only update if target exists and is different from current
  if [[ -f "$target_config" ]]; then
    # Get current symlink target (if it's a symlink)
    local current_target=""
    if [[ -L "$config_link" ]]; then
      current_target=$(readlink "$config_link" 2>/dev/null)
    fi

    # Update symlink if needed
    if [[ "$current_target" != "$target_config" ]]; then
      ln -sf "$target_config" "$config_link"
    fi
  fi
}

# Run at shell startup
_claude_statusline_switch
