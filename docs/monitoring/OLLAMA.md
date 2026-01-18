# Ollama Log Intelligence

AI-powered log enrichment and analysis using Ollama.

## Overview

Cribl Edge can route log copies to Ollama for AI-powered enrichment:

- Error classification and categorization
- Summary generation for long runs
- Anomaly detection on patterns
- Root cause analysis suggestions

## Architecture

```text
Logs → Cribl Edge → Ollama (enrichment) → Enriched logs → Cribl Cloud
                 ↘ Original logs → Cribl Cloud
```

Both original and enriched logs are shipped to Cribl Cloud for long-term storage and analysis.

## Ollama Configuration

### Model Selection

| Use Case | Recommended Model | Reason |
|----------|-------------------|--------|
| Error classification | `qwen3-next:latest` | Fast, good at categorization |
| Summarization | `qwen3-next:8b` | Balanced speed/quality |
| Root cause analysis | `qwen3-coder:30b` | Deep reasoning for code issues |
| Anomaly detection | `qwen3-next:latest` | Pattern recognition |

### Ollama API

```bash
# Verify Ollama is running
curl http://localhost:11434/api/version

# List available models
curl http://localhost:11434/api/tags
```

## Cribl Edge Pipeline

### Error Classification

Enrich error logs with AI classification:

```javascript
// Pipeline function in Cribl Edge
if (__e.event === 'error' || __e.level === 'error') {
  const response = await C.Fetch.request(
    'http://ollama:11434/api/generate',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'qwen3-next:latest',
        prompt: `Classify this error into one of: [network, auth, permission, resource, config, code, unknown]. Error: ${__e.message}. Respond with only the category.`,
        stream: false
      })
    }
  );
  __e.ai_classification = JSON.parse(response.body).response.trim();
}
```

### Run Summarization

Generate summaries for completed runs:

```javascript
if (__e.event === 'run_completed' && __e.duration_minutes > 30) {
  const taskList = __e.tasks_completed.join(', ');
  const response = await C.Fetch.request(
    'http://ollama:11434/api/generate',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'qwen3-next:8b',
        prompt: `Summarize this auto-claude run in 2-3 sentences: ` +
          `Repository: ${__e.repo}, Duration: ${__e.duration_minutes} min, ` +
          `Cost: $${__e.total_cost}, Tasks: ${taskList}`,
        stream: false
      })
    }
  );
  __e.ai_summary = JSON.parse(response.body).response.trim();
}
```

### Anomaly Detection

Flag unusual patterns:

```javascript
// Compare against rolling baseline
const baseline = C.State.get('baseline_' + __e.repo);
if (baseline) {
  if (__e.total_cost > baseline.avg_cost * 2) {
    __e.anomaly = 'high_cost';
    __e.anomaly_detail = `Cost ${__e.total_cost} is ${(__e.total_cost / baseline.avg_cost * 100).toFixed(0)}% of baseline`;
  }
  if (__e.duration_minutes > baseline.avg_duration * 2) {
    __e.anomaly = 'long_duration';
  }
}

// Update baseline (simple moving average)
C.State.set('baseline_' + __e.repo, {
  avg_cost: baseline ? (baseline.avg_cost + __e.total_cost) / 2 : __e.total_cost,
  avg_duration: baseline ? (baseline.avg_duration + __e.duration_minutes) / 2 : __e.duration_minutes
});
```

### Root Cause Analysis

For failures, suggest potential causes:

```javascript
if (__e.event === 'run_completed' && __e.exit_code !== 0) {
  const response = await C.Fetch.request(
    'http://ollama:11434/api/generate',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'qwen3-coder:30b',
        prompt: `Analyze this failure and suggest 3 potential root causes. ` +
          `Error: ${__e.error_message}. Context: Repository ${__e.repo}, ` +
          `exit code ${__e.exit_code}. Format as numbered list.`,
        stream: false
      })
    }
  );
  __e.ai_root_cause = JSON.parse(response.body).response.trim();
}
```

## Performance Considerations

### Latency

- Ollama inference adds 100ms-2s per log depending on model size
- Use smaller models for high-volume enrichment
- Consider async processing for non-critical enrichment

### Resource Usage

| Model | RAM Required | GPU VRAM |
|-------|--------------|----------|
| qwen3-next:latest | 8GB | 6GB |
| qwen3-next:8b | 16GB | 10GB |
| qwen3-coder:30b | 32GB | 24GB |

### Batching

For high-volume logs, batch requests:

```javascript
// Accumulate logs
if (!C.State.get('batch')) C.State.set('batch', []);
C.State.get('batch').push(__e);

// Process batch every 10 events
if (C.State.get('batch').length >= 10) {
  const batch = C.State.get('batch');
  C.State.set('batch', []);

  const errors = batch.filter(e => e.level === 'error').map(e => e.message);
  if (errors.length > 0) {
    const response = await C.Fetch.request(
      'http://ollama:11434/api/generate',
      {
        method: 'POST',
        body: JSON.stringify({
          model: 'qwen3-next:latest',
          prompt: `Classify these ${errors.length} errors: ${errors.join('; ')}. Return classifications as comma-separated list.`,
          stream: false
        })
      }
    );
    // Parse and apply classifications
  }
}
```

## Kubernetes Deployment

### Ollama Pod (Optional)

If running Ollama in K8s alongside other monitoring:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
        - name: ollama
          image: ollama/ollama:latest
          ports:
            - containerPort: 11434
          resources:
            limits:
              memory: "16Gi"
              # nvidia.com/gpu: 1  # If GPU available
          volumeMounts:
            - name: models
              mountPath: /root/.ollama
      volumes:
        - name: models
          persistentVolumeClaim:
            claimName: ollama-models
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: monitoring
spec:
  selector:
    app: ollama
  ports:
    - port: 11434
      targetPort: 11434
```

## Troubleshooting

### Ollama Not Responding

```bash
# Check Ollama is running
curl http://localhost:11434/api/version

# Check logs
~/Library/Logs/Ollama/ollama.log
```

### Model Not Found

```bash
# Pull required model
ollama pull qwen3-next:latest
```

### Slow Inference

1. Use a smaller model for high-volume enrichment
2. Enable GPU acceleration if available
3. Batch requests to reduce overhead

## Related Documentation

- [Kubernetes Setup](./KUBERNETES.md)
- [OTEL Configuration](./OTEL.md)
- [Main Monitoring Overview](../MONITORING.md)
