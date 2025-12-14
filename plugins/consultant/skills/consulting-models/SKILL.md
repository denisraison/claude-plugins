---
name: consulting-models
description: Multi-model AI consultation and research using cursor-agent. Supports CONSULTATION (single query to specific model), RESEARCH (parallel multi-agent queries), and DELIBERATION (multi-round debate). Use when user says 'ask gpt', 'ask opus', 'consult gemini', 'do research on', 'deliberate on', or wants second opinions from AI models.
---

# Consulting Models

Multi-model consultation using cursor-agent CLI.

## Operation Modes

### 1. CONSULTATION (Single Expert)

Ask a specific AI model for focused analysis.

**Triggers:** "Ask [model] about", "Consult [model] on", "What does [model] think"

**Models:** gpt, opus, gemini

**Execute:**
```bash
scripts/consult.sh "MODEL" "PROMPT"
```

Replace MODEL with alias, PROMPT with question. Output goes to stdout.

### 2. RESEARCH (Parallel Multi-Agent)

Launch multiple agents for comprehensive coverage.

**Triggers:** "Do research on", "Quick research:", "Extensive research on"

**Intensities:**
- quick: 3 agents (1 per model)
- standard: 9 agents (3 per model)
- extensive: 24 agents (8 per model)

**Execute:**
```bash
scripts/research.sh "TOPIC" INTENSITY OUTPUT_DIR
scripts/collect.sh OUTPUT_DIR
```

See `references/research-workflow.md` for full workflow.

### 3. DELIBERATION (Multi-Round Debate)

Agents critique each other and refine positions over 4 rounds.

**Triggers:** "Deliberate on", "Have models debate", "Peer review:"

See `references/deliberation-workflow.md` for full protocol.

## Quick Reference

```bash
# Single consultation
scripts/consult.sh "gpt" "What's the best rate limiting approach?"

# Parallel research
scripts/research.sh "API authentication" standard ./scratch/research
scripts/collect.sh ./scratch/research
```

## Model Selection

| Model | Best For |
|-------|----------|
| gpt | Complex reasoning, technical analysis |
| opus | Code-focused, high reasoning |
| gemini | Multi-perspective analysis |

Full details: `references/models.md`

## Synthesis

After collecting results:
1. Identify consensus (3+ models agree)
2. Note disagreements
3. Rate confidence (High/Medium/Low)
4. Provide recommendation

Template: `references/synthesis-template.md`
