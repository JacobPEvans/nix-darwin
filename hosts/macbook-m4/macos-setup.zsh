# macOS-specific setup and cleanup

# Set tabs to 2 spaces
tabs -2

# Homebrew: update package index on shell start.
# Runs in the foreground so available updates are visible immediately.
# Note: onActivation.autoUpdate = false keeps darwin-rebuild fast; this compensates.
brew update

# Clean up .DS_Store files in common directories.
# Single find across all dirs; -exec rm {} + batches args for fewer rm invocations.
# Runs in the background to avoid blocking shell startup.
{ find ~/.config/ ~/git/ ~/obsidian/ -name ".DS_Store" -depth -exec rm {} + 2>/dev/null; } &!
