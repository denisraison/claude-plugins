# Research Mode Workflow

## Step 1: Decompose the Query

Break the topic into focused sub-questions. For standard research (15 agents), create angles that cover different perspectives.

Example for "API authentication best practices":
- OAuth 2.0 vs API keys comparison
- JWT security considerations
- Session management patterns
- Rate limiting for authenticated endpoints
- Token refresh strategies

## Step 2: Launch Parallel Research

```bash
# Create output directory
OUTPUT_DIR="./scratch/research-$(date +%s)"

# Launch research
scripts/research.sh "API authentication best practices" standard "$OUTPUT_DIR"
```

## Step 3: Wait for Completion

The script waits for all agents. Typical times:
- quick: 30-60 seconds
- standard: 60-90 seconds
- extensive: 2-3 minutes

## Step 4: Collect Results

```bash
scripts/collect.sh "$OUTPUT_DIR"
```

## Step 5: Synthesise Findings

Review all agent responses and synthesise using `synthesis-template.md`.

Key tasks:
- Identify consensus points (3+ models agree)
- Note significant disagreements
- Assign confidence levels
- Provide actionable recommendation

## Timeout Handling

If agents take too long:
1. Check which results are available
2. Synthesise partial results
3. Note which models are missing
4. Offer to retry missing agents
