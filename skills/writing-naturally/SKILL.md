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

A document can be clean sentence by sentence and still read badly as a whole. The rules above catch the first problem, not the second. So the check has two passes, and a grep for dashes or banned words is neither of them.

### Pass 1: the whole document

Do this first, reading top to bottom in one go. Never judge from the diff or from the parts you just edited. Documents that grew by patching (a new layer added on top, a section rewritten in place) are where repetition and contradictions hide.

1. Write down who reads it and what they need to walk away with, in one line. Cut or merge any section that doesn't serve that.
2. List the key claims, rules and numbers, and count where each one appears. Each should live in one place. A second mention is fine only as a short pointer.
3. For every decision or rule (who does what, when to use which option, what is forbidden), check that every place that mentions it agrees. Look hardest where a list, a table and a script or example all cover the same thing.
4. Check that no section only restates another document the reader also has. Point to it instead.
5. Check that the order follows what the reader needs first, not the order things were researched or written.

### Pass 2: sentences

Go through the style rules above.

### Score

Score both passes 1 to 10 for AI sloppiness, and report both:
- 1-3: natural, reads like a human wrote it
- 4-6: some tells, needs a pass
- 7-10: obvious AI output, rewrite

Target: 3 or below on both. The document score is the one that usually fails.

### When someone else reviews it

The author is anchored on what they meant to write. For documents that go to other people, have a reviewer who did not write it read the final text cold. Give it the reader and purpose, not your summary of what changed. Ask for repetition, contradictions and anything unclear, with the place in the text. A sub-agent that rewrites a file and reports its own score is not this review, and its score covers only the file it touched. Read the final text yourself before calling it done.

## When Corrected

If the user points out sloppy phrasing, fix it immediately and remember the pattern for the rest of the session. Common corrections from past sessions:
- Too many dashes
- Numbered section titles when not needed
- Vocabulary that sounds academic ("empirically", "facilitates")
- Redundant sections saying the same thing twice
- A document scored 3 sentence by sentence that repeated the same fact four or five times and contradicted itself between a script and a rule. It had grown by adding layers on top of existing sections, and the review only looked at the edits.
- Including specific line numbers when referencing source files (e.g. "see `foo.ts` (lines 82-180)"). Line numbers go stale and scream AI-generated.
- Excessive inline source file paths. A path here and there for key entry points is fine. But when every paragraph has one in parentheses it reads like a machine dumping search results. Use short names in prose ("the cache refresh worker") and put full paths in a reference table if needed.
