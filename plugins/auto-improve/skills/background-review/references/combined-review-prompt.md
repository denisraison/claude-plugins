Review the conversation above and update two things:

**Memory**: who the user is. Did the user reveal persona, desires, preferences, personal details, or expectations about how you should behave? Save facts about the user and durable preferences with the memory tool.

**Skills**: how to do this class of task. Be ACTIVE, most sessions produce at least one skill update. A pass that does nothing is a missed learning opportunity, not a neutral outcome.

Target shape of the skill library: CLASS-LEVEL skills with a rich SKILL.md and a `references/` directory for session-specific detail. Not a long flat list of narrow one-session-one-skill entries.

Signals that warrant a skill update (any one is enough):
  - User corrected your style, tone, format, legibility, verbosity, or approach. Frustration is a FIRST-CLASS skill signal, not just a memory signal. "stop doing X", "don't format like this", "I hate when you Y", embed the lesson in the skill that governs that task so the next session starts fixed.
  - Non-trivial technique, fix, workaround, or debugging path emerged.
  - A skill that was loaded or consulted turned out wrong, missing, or outdated, patch it now.

Preference order for skills, pick the earliest that fits:
  1. UPDATE A CURRENTLY-LOADED SKILL. Check what skills were loaded via /skill-name or referenced in the conversation. If one of them covers the learning, PATCH it first. It was in play; it's the right place.
  2. UPDATE AN EXISTING UMBRELLA (list existing skills under $CLAUDE_CONFIG_DIR/skills/ to find the right one). Patch it.
  3. ADD A SUPPORT FILE under an existing umbrella. Three kinds: `references/<topic>.md` for session-specific detail OR condensed knowledge banks (quoted research, API docs excerpts, domain notes) written concise and task-focused; `templates/<name>.<ext>` for starter files meant to be copied and modified; `scripts/<name>.<ext>` for statically re-runnable actions (verification, fixture generators, probes). Add a one-line pointer in SKILL.md so future agents find them.
  4. CREATE A NEW CLASS-LEVEL UMBRELLA when nothing exists. Name at the class level, NOT a PR number, error string, codename, library-alone name, or "fix-X / debug-Y" session artifact. If the name only fits today's task, fall back to (1), (2), or (3).

User-preference embedding: when the user complains about how you handled a task, update the skill that governs that task. Memory alone isn't enough. Memory says "who the user is and what the current situation and state of your operations are"; skills say "how to do this class of task for this user". Both should carry user-preference lessons when relevant.

If you notice overlapping existing skills, mention it in your output.

Protected skills (DO NOT edit these):
  - Anything under a plugin directory (`plugins/*/skills/<name>/`, including under the Claude config dir's plugin cache). These ship with a plugin and get overwritten on update.
  - Anything outside the skills directory printed at the top of this prompt.
You may only edit skills under the skills directory printed at the top of this prompt. If the only skills that need updating are protected, say "Nothing to save." and stop.

Do NOT capture as skills or memory (these become persistent self-imposed constraints that bite you later when the environment changes):
  - Environment-dependent failures: missing binaries, fresh-install errors, post-migration path mismatches, "command not found", unconfigured credentials, uninstalled packages. The user can fix these, they are not durable rules.
  - Negative claims about tools or features ("browser tools do not work", "X tool is broken", "cannot use Y"). These harden into refusals the agent cites against itself for months after the actual problem was fixed.
  - Session-specific transient errors that resolved before the conversation ended. If retrying worked, the lesson is the retry pattern, not the original failure.
  - One-off task narratives. A user asking "summarize today's market" or "analyze this PR" is not a class of work that warrants a skill.

If a tool failed because of setup state, capture the FIX (install command, config step, env var to set) under an existing setup or troubleshooting skill, never "this tool does not work" as a standalone constraint.

Write memory as declarative facts, not imperatives. "User prefers concise responses" yes; "Always respond concisely" no. Imperative phrasing gets re-read as a directive in later sessions and can override the user's current request.

Memory and skill write paths are passed in via the calling script and printed at the top of this prompt under "Write locations for this run". Use those exact paths, do not derive your own. Every skill you create or modify MUST include `created_by: auto-improve` in its YAML frontmatter so audit tools and future curators can tell agent-written skills apart from hand-written ones. When you UPDATE an existing skill that already has `created_by: user` or no `created_by` field, you must:
  1. Not change the existing `created_by` value (do not overwrite to `auto-improve`).
  2. Be more conservative: only patch obvious bugs, missing steps, or user-confirmed corrections. Do not restructure or reword user-authored skills.
For new skills, the frontmatter should look like:
```
---
name: <skill-name>
description: <one line, third person, what it does and when to use it>
created_by: auto-improve
---
```

Act on whichever of the two dimensions has real signal. If genuinely nothing stands out on either, say "Nothing to save." and stop, but don't reach for that conclusion as a default.
