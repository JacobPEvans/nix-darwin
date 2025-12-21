# Copilot Review Suppression List

This document tracks specific patterns, files, and issues that Copilot should **NEVER** comment on during code reviews.

## Purpose

As we use Copilot for PR reviews, we'll identify:

1. False positives (Copilot flags something that's actually correct)
2. Noise (Copilot comments on things we don't care about)
3. Context misunderstandings (Copilot suggests changes that don't fit this repo)

**When you see a bad review comment from Copilot**, add it here so we can suppress similar comments in the future.

## How to Use This File

1. **During PR review**: If Copilot makes a bad comment, note the pattern
2. **Update this file**: Add the pattern to the appropriate section below
3. **Reference in responses**: When rejecting a Copilot suggestion, cite this file
4. **Periodic cleanup**: Update `.instructions.md` files to incorporate common patterns

## Suppression Categories

### 1. Personal Configuration Paths

**Don't comment on these paths** (this is a personal config, not a generic template):

- `/Users/jevans/` - Correct user home directory
- `~/git/nix-config/` - Correct repo location
- `jevans` as username - Correct username in examples
- `macbook-m4` as hostname - Correct host identifier

**Examples of bad comments to suppress**:

- "Consider using a variable for the username"
- "Hardcoded path should be configurable"
- "Replace `/Users/jevans/` with `$HOME`" (when Nix needs literal path)

### 2. Intentional Nix Patterns

**Don't suggest these changes**:

- "Use nix-env to install packages" - This repo is flakes-only
- "Enable nix.enable = true" - Conflicts with Determinate Nix
- "Add to Homebrew" - Nixpkgs first policy
- "Split this file" - Unless >500 lines, organization is intentional
- "Remove comments" - Verbose comments are for learning

### 3. Linter-Covered Issues

**Don't comment on these** (automated tools handle them):

- Line length in markdown (markdownlint MD013)
- Code formatting (nixfmt, prettier)
- Import ordering (handled by formatters)
- Trailing whitespace (pre-commit hooks)
- Unused variables flagged by linters

### 4. False Positive Security Warnings

**These are not security issues in this context**:

- Hardcoded Slack channel IDs - Public workspace channels, not secrets
- Localhost URLs in K8s manifests - Container networking, not exposed
- Example API endpoints in docs - Placeholders for learning
- Git commit example messages - Not real commits

### 5. Over-Engineering Suggestions

**Don't suggest adding these unless there's a real need**:

- Try/catch for Nix evaluation - Nix fails fast by design
- Error handling in shell scripts for infallible operations
- Abstraction layers for 1-time operations
- Feature flags for personal config
- Environment variables for constants

## Specific File Suppressions

### PLANNING.md and CHANGELOG.md

**Don't review** (these are working documents, not code):

- Task list formatting
- Incomplete sentences in notes
- Personal shorthand
- Future plans without implementation details

### flake.lock

**Never review** (auto-generated file):

- Any content changes
- JSON structure
- Version pins (unless explicitly discussing an update)

### .github/workflows/\*.yml

**Don't suggest** unless broken:

- Different CI/CD tools
- More comprehensive testing (we have what we need)
- Caching strategies (unless clear performance issue)

### modules/monitoring/docs/\*.md

**Don't suggest** (working documentation):

- Splitting long troubleshooting guides
- Removing "redundant" examples (they show alternatives)
- Making examples generic (they're specific to this setup)

## Common Bad Review Patterns

### Pattern: "Consider adding tests"

**Suppress unless**:

- Suggesting specific test cases for complex logic
- Identifying untested edge cases in critical code
- Pointing to existing test patterns to follow

**Don't say**:

- Generic "consider adding tests" on every function
- "This should have unit tests" without specifics

### Pattern: "This could be more efficient"

**Suppress unless**:

- Identifying actual performance bottleneck (O(n²) → O(n))
- Showing measurable improvement (benchmarks)
- Code is in a hot path and optimization matters

**Don't say**:

- Theoretical performance improvements
- Micro-optimizations without profiling
- "This could be cached" for one-time operations

### Pattern: "Extract this to a function"

**Suppress unless**:

- Code is duplicated 3+ times
- Function would be reusable across files
- Extraction clarifies complex logic

**Don't say**:

- Extract every 5-line block
- Create single-use helper functions
- Abstract for hypothetical future use

### Pattern: "Add error handling"

**Suppress for**:

- Internal functions with guaranteed inputs
- Operations that can't fail (type-safe, validated)
- Nix code (fails fast by design)

**Only suggest for**:

- External API calls
- User input validation
- File I/O operations
- Network operations

## Review Comment Templates

When rejecting bad Copilot suggestions, reference this file:

```markdown
Acknowledged but not implementing.

This is covered in `.github/instructions/DO-NOT-REVIEW.md` section X:
[Brief explanation why this doesn't apply]
```

## Maintenance

**Review this file quarterly** to identify patterns that should be:

1. Added to `.instructions.md` files (if pattern is common)
2. Removed from this file (if no longer applicable)
3. Escalated to Copilot feedback (if it's a product issue)

---

## Changelog

- 2024-12-20: Initial creation with common patterns from monitoring PR review
