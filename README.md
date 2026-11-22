# Skills

My agent skills. They follow the Agent Skills format, so they work in Claude Code and in other agents that read it. Only Claude Code is tested.

| Skill | What it does |
| --- | --- |
| `writing-naturally` | Keeps docs, PR descriptions and other prose plain and natural instead of AI-sounding. |
| `logo-design` | Generates, scores and refines logo concepts with the Gemini image API. Needs an agent that can view images. |
| `excalidraw-diagrams` | Turns a described flow or architecture into an editable `.excalidraw` diagram. |
| `qa-scenarios` | Writes user-impact QA test scenarios for a code change. |

## Install

Claude Code:

```sh
claude plugin marketplace add denisraison/skills
claude plugin install skills@dnix
```

Any other agent:

```sh
npx skills add denisraison/skills -g
```

## Which tool for which job

- Specs, spikes and design review: [EGM](https://github.com/google/elephant-goldfish-model) (`egm-brainstorm`, `egm-draft`, `egm-review`, `egm-lite`), installed as its own plugin.
- Reviewing and cleaning up a diff: the built-in `/code-review` and `/simplify`.
- Everything else: the model's defaults. A new skill gets written here only when a real task needs one.

## Reference

Matt Pocock's skills are kept as a local reference, not installed:

```sh
git clone --depth 50 https://github.com/mattpocock/skills scratch/mattpocock-skills/repo
```

## Licence

MIT.
