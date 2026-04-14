# macOS-specific setup and cleanup

# Set tabs to 2 spaces
tabs -2

# Homebrew: update + doctor once per day; outdated versions on every start.
_brew_stamp="${TMPDIR:-/tmp}/.brew_daily_$(date +%Y%m%d)"
if [[ ! -f "$_brew_stamp" ]]; then
  touch "$_brew_stamp"
  brew update
  brew doctor
fi
brew outdated --verbose

# Clean up .DS_Store files in common directories.
# Single find across all dirs; -exec rm {} + batches args for fewer rm invocations.
# Runs in the background to avoid blocking shell startup.
{ find ~/.config/ ~/git/ ~/obsidian/ -name ".DS_Store" -depth -exec rm {} + 2>/dev/null; } &!
