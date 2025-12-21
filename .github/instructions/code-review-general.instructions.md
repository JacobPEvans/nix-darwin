---
applyTo:
  - "**/*"
---

# General Code Review Instructions

## What to Focus On

### High Priority (Always Review)

- **Actual bugs and logic errors** - Code that will fail at runtime
- **Security vulnerabilities** - Obvious security issues (injection, exposed secrets, unsafe operations)
- **Breaking changes** - Changes that break existing functionality
- **Resource leaks** - Unclosed files, connections, memory leaks
- **Race conditions** - Concurrency issues, async bugs
- **Incorrect assumptions** - Code that assumes conditions that may not hold
- **Data loss risks** - Operations that could destroy data without backup

### Medium Priority (Review if Significant)

- **Performance issues** - Only if obvious and impactful (O(n²) where O(n) is easy)
- **Code duplication** - Only if it's substantial duplication (not 2-3 similar lines)
- **Inconsistency with codebase patterns** - Only if it breaks established patterns
- **Confusing variable names** - Only if genuinely misleading (not just "could be better")
- **Missing error handling** - Only for external boundaries (user input, API calls, file I/O)

### Low Priority (Usually Skip)

- **Minor style issues** - Let linters handle formatting
- **Theoretical edge cases** - Don't suggest defensive code for impossible conditions
- **Premature optimization** - Don't suggest optimizations unless there's a clear problem
- **Over-engineering suggestions** - Don't suggest abstractions for simple code
- **Personal preference** - Don't comment on valid alternative approaches

## What NOT to Review

### Never Comment On These

1. **Issues Already Covered by Linters**
   - Formatting, indentation, spacing
   - Line length (unless it's egregious and blocks readability)
   - Import ordering
   - Unused variables (if linter catches them)

2. **Defensive Programming for Impossible Conditions**
   - Don't suggest try/catch for code that can't throw
   - Don't suggest null checks for values guaranteed non-null by types
   - Don't suggest error handling for internal functions with known, controlled inputs

3. **Generic Suggestions Without Specifics**
   - "Consider adding tests" (without suggesting which scenarios)
   - "This could be refactored" (without explaining how and why)
   - "Think about performance" (without identifying actual bottlenecks)

4. **Praise or Acknowledgment Comments**
   - "Great work!"
   - "Nice catch!"
   - "LGTM" on individual lines
   - Any comment that doesn't add technical value

5. **Changes Unrelated to PR Purpose**
   - Suggesting new features not in scope
   - Refactoring unrelated code
   - Style changes in code not modified by the PR

6. **Repeat Feedback**
   - If you've commented on a pattern once, don't comment on every instance
   - Batch similar issues: "This pattern appears in 5 places: ..."

## Comment Limits

- **50-comment limit per PR** - Stop reviewing after 50 comments
- After 50 comments, the PR needs human judgment, not more AI feedback
- Batch related feedback into single comments when possible

## Review Posture

### Be Concise

- Get to the point in 1-2 sentences
- Skip pleasantries
- One suggestion per comment unless tightly related

### Be Constructive

- Suggest specific fixes with code examples when possible
- Explain WHY briefly (1 sentence)
- If unsure, say "Consider..." instead of "You must..."

### Be Respectful of Context

- This is a personal nix-darwin configuration (not a shared library)
- User is learning Nix - verbose comments are intentional
- Flakes-only approach is required (don't suggest nix-env, nix-channels)
- Determinate Nix compatibility is required (don't suggest enabling nix-darwin's nix.enable)

## Examples of Good vs Bad Comments

### ❌ Bad: Vague Variable Name Comment

```markdown
nit: This could be more descriptive
```

**Why bad**: Vague, doesn't explain what or why

### ✅ Good: Specific Variable Name Suggestion

```markdown
Variable `data` is used for user analytics throughout this component.
Rename to `userAnalytics` for clarity.
```

**Why good**: Specific, explains context, suggests concrete fix

### ❌ Bad: Generic Error Handling Comment

```markdown
Consider adding error handling here
```

**Why bad**: Too generic, no specifics

### ✅ Good: Specific Error Handling Suggestion

```markdown
`fetchUserData()` calls an external API and could throw network errors.
Wrap in try/catch to handle connection failures gracefully.
```

**Why good**: Identifies specific risk, explains why error handling is needed

### ❌ Bad: Praise Without Technical Value

```markdown
Great refactoring! This is much cleaner.
```

**Why bad**: Praise comment, no technical value

### ✅ Good: Technical Explanation

```markdown
Extracting this to a helper reduces duplication across 3 components
and makes the logic testable. ✓
```

**Why good**: Explains technical benefit, still brief
