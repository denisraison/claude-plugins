---
name: self-evaluating
description: This skill should be used when creating or editing documents, diagrams, handover docs, PEPs, or any substantial written output. Also activates when the user says "evaluate this", "run in a loop until good", "rate this out of 10", "is this 10/10", "loop until fixed", "keep improving", or asks for iterative quality improvement on any output.
---

# Self-Evaluating Output

Run a quality check on documents, diagrams, and written output before presenting. Iterate when the result is not good enough.

## When to Evaluate

- After drafting or significantly editing a document
- After creating or modifying a diagram
- When the user explicitly asks for evaluation
- When the user says "loop until it's good" or similar

## Evaluation Criteria

Score each dimension 1-10:

| Dimension | What to check |
|-----------|--------------|
| **Accuracy** | Everything factually correct based on the code? No guesses stated as facts. |
| **Clarity** | Someone with basic context can follow without re-reading? |
| **Completeness** | Obvious gaps or missing pieces? |
| **Natural voice** | Reads like a human wrote it? (Apply writing-naturally skill criteria) |

For **diagrams only**, add:

| Dimension | What to check |
|-----------|--------------|
| **Visual flow** | Clear start and end points? No spaghetti? |
| **Labels** | Every arrow and connection labelled? |
| **Accessibility** | Someone with no system knowledge can follow the flow? |

## Process

1. Draft the output
2. Evaluate against the criteria above
3. If any dimension scores below 7, fix those areas
4. Re-evaluate after fixes
5. Present when all dimensions hit 7+

When the user asks to "loop until 10/10" or similar, keep iterating until all scores hit 8+. State what improved between iterations.

## For Diagrams

- Follow C4 framework conventions (context, container, component levels) when applicable
- Group related elements visually
- Avoid scattered layouts -- proximity implies relationship
- Test readability: could someone unfamiliar with the system understand the flow?

## Anti-Patterns

- Do not present a draft and say "let me know if you want changes" without self-evaluating first
- Do not rate something 9/10 to avoid iterating -- be honest
- Do not describe what you improved without actually improving it
