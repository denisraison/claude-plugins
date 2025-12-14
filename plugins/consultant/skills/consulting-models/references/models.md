# Available Models

## gpt
- **Model ID:** gpt-5.2-high
- **Strengths:** Advanced reasoning, technical deep-dives, complex analysis
- **Best for:** Architecture decisions, debugging complex issues, technical research

## opus
- **Model ID:** opus-4.5-thinking
- **Strengths:** Code-focused, high reasoning effort
- **Best for:** Code review, implementation suggestions, step-by-step reasoning

## gemini
- **Model ID:** gemini-3-pro
- **Strengths:** Multi-perspective analysis, creative solutions
- **Best for:** Exploring alternatives, brainstorming, trade-off analysis

## Adding New Models

Edit `scripts/models.conf`:
```
newmodel|model-id-here|Description of the model
```

Then use: `./scripts/consult.sh newmodel "prompt"`
