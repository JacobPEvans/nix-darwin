# Splunk Queries and Dashboards

SPL queries for analyzing Claude Code and Auto-Claude activity.

## Index Configuration

All Claude logs should be indexed in the `claude` index with appropriate sourcetypes:

| Sourcetype | Description | Source |
|------------|-------------|--------|
| `auto_claude:jsonl` | Auto-claude structured events | `~/.claude/logs/*.jsonl` |
| `auto_claude:summary` | Human-readable summaries | `~/.claude/logs/summary.log` |
| `auto_claude:failure` | Failed runs | `~/.claude/logs/failures.log` |
| `ollama:log` | Ollama server logs | `~/Library/Logs/Ollama/*.log` |

## Common Searches

### Activity Overview

All Claude activity by event type:

```spl
index=claude sourcetype=auto_claude:jsonl
| stats count by event
| sort -count
```

### Cost Tracking

Daily cost breakdown:

```spl
index=claude event="run_completed"
| timechart span=1d sum(total_cost) as daily_cost
```

Weekly cost by repository:

```spl
index=claude event="run_completed"
| timechart span=1w sum(total_cost) by repo
```

Cost distribution by task type:

```spl
index=claude event="task_completed"
| stats sum(cost) as total_cost, count by task
| sort -total_cost
```

### Failed Runs

All failed runs with error details:

```spl
index=claude event="run_completed" exit_code!=0
| table _time repo exit_code error_message duration_minutes
| sort -_time
```

Failure rate trend:

```spl
index=claude event="run_completed"
| eval status=if(exit_code=0, "success", "failure")
| timechart span=1d count by status
```

### Subagent Analysis

Subagent performance by type:

```spl
index=claude event="subagent_completed"
| stats avg(duration_sec) as avg_duration, avg(cost) as avg_cost, count by type
| sort -count
```

Slowest subagent runs:

```spl
index=claude event="subagent_completed"
| sort -duration_sec
| head 20
| table _time repo type duration_sec cost
```

### Context Usage

Context usage trends by repository:

```spl
index=claude event="context_checkpoint"
| timechart avg(usage_pct) by repo
```

Runs approaching context limits:

```spl
index=claude event="context_checkpoint" usage_pct>80
| table _time repo usage_pct tokens_used tokens_remaining
| sort -_time
```

### Budget Monitoring

Budget utilization:

```spl
index=claude event="budget_checkpoint"
| timechart avg(remaining_pct) by repo
```

Runs exceeding budget:

```spl
index=claude event="run_completed"
| where total_cost > budget
| table _time repo total_cost budget
```

## Saved Searches

Create these as saved searches/alerts in Splunk:

### High Cost Alert

Triggers when a single run exceeds $20:

```spl
index=claude event="run_completed" total_cost>20
| table _time repo total_cost budget duration_minutes
```

Alert: Real-time, trigger per result

### Failure Spike

Triggers when failure rate exceeds 20% in the last hour:

```spl
index=claude event="run_completed" earliest=-1h
| stats count(eval(exit_code=0)) as success, count(eval(exit_code!=0)) as failure
| eval failure_rate = failure/(success+failure)*100
| where failure_rate > 20
```

Alert: Scheduled every 15 minutes

### Context Exhaustion

Triggers when context usage exceeds 90%:

```spl
index=claude event="context_checkpoint" usage_pct>90
| table _time repo usage_pct tokens_remaining run_id
```

Alert: Real-time, trigger per result

### Subagent Bottleneck

Identifies subagent types with unusually high duration:

```spl
index=claude event="subagent_completed"
| stats avg(duration_sec) as avg_duration, stdev(duration_sec) as stdev_duration by type
| eval threshold = avg_duration + 2*stdev_duration
| where avg_duration > 300
| table type avg_duration threshold
```

Alert: Scheduled daily

## Dashboards

### Auto-Claude Overview Dashboard

Panels to include:

1. **Run Status** - Single value showing success rate
2. **Daily Costs** - Timechart of total_cost by day
3. **Active Repositories** - Table of recent runs by repo
4. **Task Distribution** - Pie chart of task types
5. **Failure Log** - Table of recent failures

### Cost Analysis Dashboard

Panels to include:

1. **Monthly Trend** - Line chart of costs over time
2. **By Repository** - Bar chart of costs by repo
3. **By Task Type** - Pie chart of costs by task
4. **Budget Utilization** - Gauge showing budget remaining

### Performance Dashboard

Panels to include:

1. **Subagent Duration** - Bar chart of avg duration by type
2. **Context Usage** - Line chart of context percentage over time
3. **Slowest Runs** - Table of longest-running tasks
4. **Error Distribution** - Pie chart of error types

## Data Model

Consider creating a data model for faster searches on high-volume data:

```spl
| datamodel create "Claude_Activity" from index=claude
| add field "event" as string
| add field "repo" as string
| add field "cost" as number
| add field "duration_sec" as number
| add field "exit_code" as number
```

## Field Extractions

Auto-extract fields from JSONL logs:

```spl
[claude_jsonl]
INDEXED_EXTRACTIONS = json
KV_MODE = json
TIME_FORMAT = %Y-%m-%dT%H:%M:%SZ
TIME_PREFIX = "timestamp":"
```

## Related Documentation

- [Kubernetes Setup](./KUBERNETES.md)
- [OTEL Configuration](./OTEL.md)
- [Main Monitoring Overview](../MONITORING.md)
