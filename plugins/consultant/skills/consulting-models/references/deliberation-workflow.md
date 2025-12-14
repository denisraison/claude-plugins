# Deliberation Mode Workflow

Multi-round debate where models critique each other and refine positions.

## Round 1: Initial Perspectives

Launch 3 agents (one per model) with the initial question.

```bash
scripts/research.sh "QUESTION" quick ./scratch/deliberation-r1
```

Collect and review initial positions.

## Round 2: Critique

For each model, create a new prompt containing:
1. The original question
2. All Round 1 responses
3. Instruction to critique other models' answers

Example prompt structure:
```
Original question: Should we use REST or GraphQL?

Round 1 responses:
- gpt: [response]
- opus: [response]
- gemini: [response]

Your task: Review all responses. Point out errors, gaps, and strong points.
Challenge assumptions. Add missing information.
```

Run critiques:
```bash
mkdir -p ./scratch/deliberation-r2
scripts/consult.sh gpt "CRITIQUE_PROMPT" ./scratch/deliberation-r2/gpt.txt &
scripts/consult.sh opus "CRITIQUE_PROMPT" ./scratch/deliberation-r2/opus.txt &
scripts/consult.sh gemini "CRITIQUE_PROMPT" ./scratch/deliberation-r2/gemini.txt &
wait
```

## Round 3: Refinement

Share all Round 2 critiques. Each model revises their position.

Prompt includes:
1. Original question
2. Their Round 1 response
3. All Round 2 critiques
4. Instruction to revise their stance

## Round 4: Final Synthesis

Analyse all three rounds:

1. **Convergence:** Did models reach consensus?
2. **Disagreements:** What points remain contested?
3. **Evolution:** How did positions change through debate?
4. **Recommendation:** Final synthesised answer

## Output Format

```markdown
## Deliberation Summary: [TOPIC]

### Consensus Points
- [Point where all/most models agree]

### Unresolved Disagreements
- [Point]: Model A says X, Model B says Y

### Position Evolution
- gpt: Changed from X to Y after critique
- opus: Refined implementation details
- gemini: Maintained position, added nuance

### Final Recommendation
[Synthesised answer based on deliberation]

### Confidence: [HIGH/MEDIUM/LOW]
Based on [degree of consensus]
```
