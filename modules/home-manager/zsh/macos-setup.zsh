# macOS-specific setup and cleanup

# Set tabs to 2 spaces
tabs -2

# Homebrew: update package index in the background.
# Keeps formulae/casks current without blocking shell startup.
# Note: onActivation.autoUpdate = false keeps darwin-rebuild fast; this compensates.
{ brew update &>/dev/null; } &!

# Clean up .DS_Store files in common directories.
# Runs in the background to avoid blocking shell startup.
{ find ~/.config/  -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null; } &!
{ find ~/git/      -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null; } &!
{ find ~/obsidian/ -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null; } &!
