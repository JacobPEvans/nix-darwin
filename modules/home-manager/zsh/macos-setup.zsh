# macOS-specific setup and cleanup

# Set tabs to 2 spaces
tabs -2

# Clean up .DS_Store files in common directories
# Runs silently in background to avoid cluttering terminal output
find ~/.config/  -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
find ~/git/      -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
find ~/obsidian/ -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
