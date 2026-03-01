# Research: Context Files for Agentic Coding

## Key Paper

**"Agent READMEs: An Empirical Study of Context Files for Agentic Coding"**
arxiv.org/abs/2511.12884 — ETH Zurich / LogicStar.ai, 2025

Tested four coding agents across hundreds of real-world GitHub issues with and without context files.

### Findings

- LLM-generated context files reduced task success by ~3% and increased inference cost by 20%+
- Developer-written files: slight improvement (+4%) but still added 19% to cost
- Codebase overviews did not help agents find relevant files faster — agents discover structure autonomously
- Agents treated every instruction as a constraint, making tasks harder not easier
- Most generated files duplicated content already in READMEs and docs

### What worked

Developer-written files with information that existed only in developers' heads, not in any committed file:
- Package manager preferences
- Specific tool versions or quirks
- Workflow steps (release process, eval loops)
- Naming conventions not enforced by tooling

### What didn't work

- Stack descriptions (agent reads go.mod / package.json)
- Directory structure (agent lists dirs)
- Product descriptions (agent reads README)
- Generic conventions (already obvious from the code)

## Instruction-following capacity

Frontier models follow ~150-200 instructions with reasonable consistency. More instructions = linear decay in compliance. Smaller models: exponential decay.

LLMs bias toward instructions at the peripheries of the prompt: beginning (system prompt + CLAUDE.md) and end (most recent user message). Middle content is less reliably followed.

## Implication

Start with an empty CLAUDE.md. Add one specific instruction only when you observe the agent repeatedly making the same mistake. This empirical method outperforms theoretically complete files.

## Related

- Upsun writeup: devcenter.upsun.com/posts/agents-md-less-is-more/
- "Beyond the Prompt: An Empirical Study of Cursor Rules" — arxiv.org/abs/2512.18925
