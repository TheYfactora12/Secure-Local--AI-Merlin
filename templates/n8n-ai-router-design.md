# n8n AI Router Design

## Logic

```
task_type = classify(task)

if task_type == 'research':
    call Perplexity sonar-pro API
elif task_type == 'coding':
    call OpenAI API (codex or gpt-4.1)
elif task_type == 'overnight':
    dispatch to OpenHands
else:
    call local Ollama (default model)

store result in Qdrant
return to user
```

## Ports
- Ollama: http://localhost:11434
- Open WebUI: http://localhost:3001
- n8n: http://localhost:5678
- Qdrant: http://localhost:6333
- OpenHands: http://localhost:3000

## Cost rule
- Local = free, always try first
- Perplexity sonar-pro = ~$0.001 per search
- OpenAI gpt-4.1 = ~$0.015 / 1K tokens
- Escalate only on failure or explicit need
