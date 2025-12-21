# Gemini Code Review Instructions

This file provides Gemini-specific guidance for conducting code reviews in this nix-darwin configuration repository.

**General AI review guidelines** are in `AGENTS.md` - this file supplements those with Gemini-specific context.

## Gemini's Review Strengths

Leverage Gemini's capabilities for:

1. **Multi-file analysis** - Understanding how changes interact across the codebase
2. **Long-range dependencies** - Tracking how changes affect distant code
3. **Documentation quality** - Gemini excels at reviewing technical writing
4. **Nix expressions** - Deep understanding of Nix language and ecosystem

## Review Focus Areas

### High Priority (Always Review)

1. **Flake input integrity**
   - Are new inputs properly declared in `flake.nix`?
   - Are inputs used in `outputs` function signature?
   - Do flake.lock hashes match expected sources?

2. **Cross-module consistency**
   - Do changes in one module break assumptions in another?
   - Are module options used consistently across the config?
   - Do changes maintain home-manager and darwin-module compatibility?

3. **Breaking changes**
   - Will this change require manual intervention after rebuild?
   - Are deprecation warnings from nixpkgs addressed?
   - Does this affect stable interfaces used in other places?

4. **Documentation completeness**
   - Are new options documented with examples?
   - Do code changes match documentation updates?
   - Are migration steps documented for breaking changes?

### Medium Priority (Review if Significant)

1. **Module organization**
   - Are new modules in the right directory?
   - Should this be split into multiple modules?
   - Are imports in logical order?

2. **Option defaults**
   - Are default values sensible for this use case?
   - Are required options clearly marked?
   - Do defaults align with upstream recommendations?

3. **Security implications**
   - Are secrets properly handled (BWS/keychain, not committed)?
   - Are file permissions appropriate?
   - Are network-facing services properly configured?

### Low Priority (Usually Skip)

- Formatting (nixfmt handles this)
- Minor rewording of comments
- Alternative implementation approaches (if current approach works)

## What NOT to Review

See `.github/instructions/DO-NOT-REVIEW.md` for comprehensive suppression list.

### Key Suppressions for Gemini

1. **Don't suggest nix-env or channels** - This is a flakes-only configuration
2. **Don't suggest enabling nix-darwin's nix.enable** - Conflicts with Determinate Nix
3. **Don't suggest making personal paths configurable** - This is a personal config, not a shared module
4. **Don't suggest splitting files under 500 lines** - Current organization is intentional
5. **Don't comment on linter-covered issues** - Pre-commit hooks handle formatting

## Nix-Specific Review Patterns

### ✅ Good: Identifying Type Mismatches

```markdown
Line 45: `environment.systemPackages` expects a list, not an attribute set.

Change:

\`\`\`nix
environment.systemPackages = {
  vim = pkgs.vim;
};
\`\`\`

To:

\`\`\`nix
environment.systemPackages = with pkgs; [ vim ];
\`\`\`
```

### ✅ Good: Catching Deprecated Options

```markdown
Line 78: `programs.vscode.userSettings` is deprecated as of home-manager 23.11.

Migrate to the new profiles API:

\`\`\`nix
programs.vscode.profiles.default.userSettings = {
  "editor.fontSize" = 14;
};
\`\`\`

Reference: <https://github.com/nix-community/home-manager/pull/4671>
```

### ❌ Bad: Suggesting Non-Flakes Approaches

```markdown
Consider using `nix-channel --add` to add this package source.
```

**Why bad**: This repo is flakes-only. Channels are not used.

### ❌ Bad: Generic Refactoring Suggestions

```markdown
This module could be refactored for better organization.
```

**Why bad**: Too vague, no specific improvement suggested

## Review Comment Format

**Preferred format** for Gemini reviews:

```markdown
**[SEVERITY]** Line X: [Brief description of issue]

[Explanation of why this is a problem]

**Suggested fix**:

\`\`\`language
[code example]
\`\`\`

**Reference**: [Link to docs/prior art if applicable]
```

**Severity levels**:

- **CRITICAL** - Breaks the build, security issue, data loss risk
- **HIGH** - Incorrect behavior, deprecated API, type mismatch
- **MEDIUM** - Suboptimal approach, inconsistency, unclear code
- **LOW** - Nit, style preference (use sparingly)

## Multi-File Review Strategy

When reviewing changes across multiple files:

1. **Identify the change's purpose** - What is this PR trying to accomplish?
2. **Trace dependencies** - Which files depend on the changed code?
3. **Check for ripple effects** - Do changes in file A require updates in file B?
4. **Verify consistency** - Are similar patterns updated consistently?

**Example**:

```markdown
**HIGH** - This change to `modules/darwin/packages.nix` adds a new package,
but the corresponding config in `modules/home-manager/shell.nix` wasn't updated.

The package `foo` requires environment variable `FOO_HOME` to be set.
Add to `modules/home-manager/shell.nix`:

\`\`\`nix
home.sessionVariables = {
  FOO_HOME = "${config.home.homeDirectory}/.foo";
};
\`\`\`
```

## Context Awareness

This is a **personal nix-darwin configuration** for learning Nix:

- **Verbose comments are intentional** - User is learning, explanations are valuable
- **Personal paths are correct** - `/Users/jevans/` is not a placeholder
- **Multiple examples are pedagogical** - Showing alternatives is educational, not redundant
- **Flakes-only is a hard requirement** - Never suggest nix-env or channels

## Integration with Other Reviewers

This repo may have multiple AI reviewers (Copilot, Gemini, Claude):

- **Don't repeat feedback** - If another reviewer already commented, add +1 or skip
- **Complement, don't duplicate** - Focus on areas where Gemini adds unique value
- **Reference other comments** - "Agreeing with @copilot-pull-request-reviewer on line 45..."

## Comment Limit

**50-comment limit per PR** - After 50 total AI comments across all reviewers:

- Stop adding new comments
- Post a summary comment if needed
- Let human judgment take over

## Feedback Loop

If you receive feedback that a review comment was incorrect or unhelpful:

- That pattern should be added to `.github/instructions/DO-NOT-REVIEW.md`
- Adjust future reviews to avoid similar comments
- Focus on higher-value feedback

---

**Last Updated**: 2024-12-20
**Referenced by**: `modules/home-manager/ai-cli/gemini-config.nix` (settings.json context.fileName)
