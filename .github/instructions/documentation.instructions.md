---
applyTo:
  - "**/*.md"
  - "!node_modules/**"
  - "!.nix/**"
---

# Documentation Review Instructions

## What to Focus On

### High Priority

- **Broken links** - Internal links to files that don't exist
- **Incorrect commands** - Commands that won't work or have wrong syntax
- **Outdated information** - References to removed files, old APIs, deprecated options
- **Security issues** - Exposed secrets, tokens, API keys in examples
- **Misleading examples** - Code examples that are incorrect or won't run

### Medium Priority

- **Incomplete instructions** - Missing critical steps in procedures
- **Unclear explanations** - Confusing wording that could mislead users
- **Missing context** - Examples without explanation of what they do
- **Inconsistent terminology** - Same concept called different things

### Low Priority (Usually Skip)

- **Minor typos** - Unless they change meaning (eg. "not" vs "now")
- **Style preferences** - Passive vs active voice, sentence structure
- **Minor formatting** - Let markdownlint handle this
- **"Could be clearer"** - Only comment if actually confusing, not just "could be better"

## What NOT to Review

### Never Comment On These

1. **Markdown Linting Issues** - Let markdownlint handle:
   - Line length (MD013)
   - Heading style (MD003, MD022, MD025)
   - List formatting (MD004, MD007, MD030)
   - Code block style (MD040, MD046)
   - Link style (MD034)

2. **Personal Configuration Details**
   - Use placeholder paths like `/Users/<username>/...` or `~` instead of literal usernames
   - Avoid hardcoding specific usernames or hostnames (use `$USER` or placeholders)
   - Personal preferences documented as configuration examples

3. **Verbose Documentation**
   - Long explanations for learning purposes
   - Multiple examples showing different approaches
   - Commented-out code showing alternatives
   - This is a learning repo - verbosity is intentional

4. **Documentation Structure**
   - Don't suggest splitting files unless 1000+ lines
   - Don't suggest combining files unless truly redundant
   - Respect existing organization

## Common Documentation Issues

### ❌ Bad: Exposed Secrets

```markdown
# Setup
export SLACK_BOT_TOKEN="xoxb-REDACTED-EXAMPLE-TOKEN"
```

**Problem**: Real token exposed in docs

**Fix**: Use placeholder

```markdown
# Setup
export SLACK_BOT_TOKEN="xoxb-YOUR-TOKEN-HERE"
```

### ❌ Bad: Incorrect Command

```markdown
# Rebuild System
nix-env -iA nixpkgs.hello
```

**Problem**: This repo uses flakes, not nix-env

**Fix**: Show correct flakes command

```markdown
# Rebuild System
sudo darwin-rebuild switch --flake .
```

### ❌ Bad: Broken Link

```markdown
See [Setup Guide](docs/setup.md) for details.
```

**Problem**: File doesn't exist (should be `SETUP.md`)

**Fix**: Correct the link

```markdown
See [Setup Guide](SETUP.md) for details.
```

## Review Examples

### ✅ Good: Correcting Incorrect Command

```markdown
Line 42: Command will fail because `nix-channel` isn't used in this flakes-only setup.

Replace with:
\`\`\`bash
nix flake update
sudo darwin-rebuild switch --flake .
\`\`\`
```

**Why good**: Identifies actual error, provides working alternative, explains why

### ❌ Bad: Vague Clarity Suggestion

```markdown
Line 42: This sentence could be reworded for clarity.
```

**Why bad**: Vague, doesn't explain what's unclear or how to improve

### ✅ Good: Fixing Broken Link

```markdown
Line 67: Link to `modules/darwin/packages.nix` is broken.

File was moved to `modules/darwin/core/packages.nix` in commit abc123.
Update link to match current location.
```

**Why good**: Identifies broken link, explains what happened, suggests specific fix

### ❌ Bad: Generic Example Suggestion

```markdown
Line 67: Consider adding more examples here.
```

**Why bad**: Generic suggestion, no specifics about what examples or why needed

## Markdown-Specific Antipatterns

### Don't Comment on These

1. **Long lines that exceed 160 chars**
   - markdownlint will catch these (MD013)
   - Only comment if it's a command that should be on multiple lines for readability

2. **Multiple blank lines**
   - markdownlint handles this (MD012)

3. **Bare URLs**
   - markdownlint handles this (MD034)
   - Only comment if URL should be a descriptive link for usability

4. **Code block without language**
   - markdownlint handles this (MD040)
   - Only comment if wrong language is specified

5. **Personal preference on heading style**
   - ATX (`#`) vs setext (`===`) is handled by linter
   - Only comment if headings are incorrect level (eg. jumping from h2 to h4)

## Documentation Context

This is a **personal nix-darwin configuration repository**:

- Use placeholder paths like `/Users/<username>/` or `~` (not literal usernames for privacy)
- Avoid hardcoding specific usernames or hostnames (use `$USER` or environment variables)
- Verbose explanations are intentional (user is learning)
- Multiple examples showing alternatives are pedagogical (not redundant)
- Comments in code examples explaining internals are valuable (not noise)

This ensures the repo is portable and usable by other contributors without exposing PII.
