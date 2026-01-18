# Survey Issues

Fetch and categorize open issues from the target repository.

## Context

Loop iteration: {{LOOP_NUMBER}}
Target repository: $MAESTRO_CURRENT_REPO

## Setup

- [ ] Change to target repository: `cd $MAESTRO_CURRENT_REPO`
- [ ] Verify git status: `git status`

## Tasks

- [ ] Fetch open issues: `gh issue list --limit 20 --json number,title,labels,body,createdAt`
- [ ] Filter out issues with labels: `ai-created`, `wontfix`, `blocked`, `in-progress`
- [ ] Write filtered issues to `issues.json` in working directory

## Output

Creates `issues.json` with structure:

```json
[
  {"number": 123, "title": "...", "labels": [...], "body": "...", "createdAt": "..."}
]
```
