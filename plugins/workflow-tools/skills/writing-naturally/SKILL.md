---
name: writing-naturally
description: This skill should be used when writing documentation, PR descriptions, handover docs, PEPs, Confluence pages, or any prose output. Activates when the user asks to "write a document", "create a handover", "update the docs", "write a PR description", "draft a PEP", or any task producing written content. Enforces natural, casual writing style and prevents AI-sloppy output.
---

# Writing Naturally

Enforce a natural, human writing voice across all prose output. This skill exists because AI-generated text has recognizable patterns that read as artificial. The goal is output that sounds like a developer explaining something to a colleague.

## Style Rules

### Tone
- Casual and direct, like talking to a teammate
- No sales pitch language, no hype, no filler

### Formatting
- Minimal use of dashes (em dashes, en dashes) -- one or two per document is fine, not every other sentence
- Do not number section titles
- Do not add a table of contents unless the document exceeds 5 pages
- Single blank line before code blocks, no extra whitespace padding
- Shorter paragraphs over dense walls of text

### Word Choice
- Simple, everyday words only
- Avoid: "leverage", "utilize", "facilitate", "comprehensive", "robust", "seamless", "cutting-edge", "tune empirically", "it's worth noting"
- Do not pad sentences with: "It should be mentioned that", "It's important to note", "As previously discussed"
- No emojis unless explicitly requested

### Structure
- Do not repeat the same point in different words
- Do not open with "In this document, we will explore..."
- Do not start consecutive bullet points with the same word
- Avoid balanced hedging like "On the other hand" unless genuinely presenting a tradeoff
- No superlatives without evidence

## Self-Check

Before presenting any written output, score it 1-10 for AI sloppiness:
- 1-3: natural, reads like a human wrote it
- 4-6: some tells, needs a pass
- 7-10: obvious AI output, rewrite

Target score: 3 or below. If above 3, rewrite the sloppy parts before presenting.

## When Corrected

If the user points out sloppy phrasing, fix it immediately and remember the pattern for the rest of the session. Common corrections from past sessions:
- Too many dashes
- Numbered section titles when not needed
- Vocabulary that sounds academic ("empirically", "facilitates")
- Redundant sections saying the same thing twice
