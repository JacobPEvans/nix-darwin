#!/bin/bash
# Claude Code Status Line Script
#
# Displays: robbyrussell-style prompt with directory, git status, model, and output style
# Input: JSON on stdin with workspace and model info
# Output: Single line status string

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
style=$(echo "$input" | jq -r '.output_style.name')

# Shorten home directory to ~ and get basename
cwd_display=${cwd/#$HOME/\~}
dir_name=$(basename "$cwd_display")

# Get git branch and status if in a git repo
git_info=""
git_dirty=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_info=" ($git_branch)"
  fi

  # Check if there are uncommitted changes
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    git_dirty=" ✗"
  fi
fi

# Only show style if it's not "default"
style_display=""
if [ "$style" != "default" ]; then
  style_display=" [$style]"
fi

# Output: arrow + directory + git info + dirty indicator | model + style
printf "➜  %s%s%s | %s%s" "$dir_name" "$git_info" "$git_dirty" "$model" "$style_display"
