# Auto-Claude Workflow

Visual representation of auto-claude's decision process.

## Main Flow

```mermaid
flowchart TD
    Start([Auto-Claude Start]) --> Preflight{Preflight Checks}

    Preflight -->|Total >= 50| Paused[Run Paused]
    Preflight -->|OK| Mode{Check Mode}

    Mode -->|enforcement_mode: PAUSED| Paused
    Mode -->|enforcement_mode: PR_FOCUS| PRFocus[PR Focus Mode]
    Mode -->|enforcement_mode: PR_CREATION| PRCreate[PR Creation Mode]
    Mode -->|enforcement_mode: CONSOLIDATION| Consolidate[Consolidation Mode]
    Mode -->|enforcement_mode: NORMAL| Normal[Normal Mode]

    PRFocus --> PR1[Fix failing CI]
    PR1 --> PR2[Resolve review comments]
    PR2 --> PR3[Merge ready PRs]
    PR3 --> PRCheck{PRs < 10?}
    PRCheck -->|No| PR1
    PRCheck -->|Yes| Normal

    PRCreate --> Create1[Close resolved issues]
    Create1 --> Create2[Create PRs for top issues]
    Create2 --> CreateCheck{Ratio < 2?}
    CreateCheck -->|No| Create1
    CreateCheck -->|Yes| Normal

    Consolidate --> Con1[Run /consolidate-issues]
    Con1 --> Con2[Deduplicate issues]
    Con2 --> Con3[Link related issues]
    Con3 --> ConCheck{Ratio < 2?}
    ConCheck -->|No| Con1
    ConCheck -->|Yes| Normal

    Normal --> Work1[Issue hygiene]
    Work1 --> Work2[Scan for work]
    Work2 --> Work3[Prioritize tasks]
    Work3 --> Work4[Dispatch sub-agents]
    Work4 --> Budget{Budget left?}
    Budget -->|Yes| Work1
    Budget -->|No| Exit([Graceful Exit])
```

## Content Routing

```mermaid
flowchart LR
    Content{Content Type?}

    Content -->|Single bug/feature| GH[GitHub Issue]
    Content -->|Fix details| PR[PR Description]
    Content -->|Session summary| Slack[Slack Thread]
    Content -->|Multi-issue update| Slack
    Content -->|Run status| Slack
```

## Enforcement Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| NORMAL | All limits OK | Work normally on all task types |
| CONSOLIDATION | AI-created >= 25 or (ratio > 3 and PRs < 5) | Focus on reducing issue count before new work |
| PR_CREATION | Ratio > 5, PRs < 3 | Skip issues, create PRs to fix existing issues |
| PR_FOCUS | Open PRs >= 10 | Resolve PRs only, no new work |
| PAUSED | Total issues >= 50 | Run skipped entirely |

## Limits

- **50 total issues**: Hard limit - run paused
- **25 AI-created issues**: Soft limit - skip issue creation
- **10 open PRs**: Triggers PR_FOCUS mode
- **3:1 ratio with < 5 PRs**: Triggers CONSOLIDATION mode
- **5:1 ratio with < 3 PRs**: Triggers PR_CREATION mode
