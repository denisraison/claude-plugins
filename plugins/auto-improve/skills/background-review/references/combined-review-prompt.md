Review the conversation above and update two things.

**Memory**: who the user is. Did the user reveal persona, desires, preferences, personal details, or expectations about how you should behave? Save facts about the user and durable preferences.

**Skills**: how to do this class of task. Most sessions warrant NO skill change. Doing nothing when nothing stands out is a successful run, not a missed one. The skill library exists for class-level instructions, not session diaries.

Target shape: CLASS-LEVEL skills with a rich SKILL.md and a `references/` directory for session-specific detail. Not a flat list of one-session-one-skill entries.

## When to update a skill (need at least one)

- User CORRECTED your style, tone, format, verbosity, or approach. Frustration is a first-class skill signal. "stop doing X", "don't format like this", "I hate when you Y" — embed the lesson in the skill that governs that task.
- A skill that was loaded or consulted turned out wrong, missing, or outdated. Patch it.
- A non-trivial technique, fix, workaround, or debugging path emerged that would help on a future session of the SAME CLASS of task.

If none of these are present, output exactly `Nothing to save.` and stop. That is the expected outcome on most sessions.

## Preference order — pick the EARLIEST that fits

1. **UPDATE A LOADED SKILL.** Check what skills appeared in the conversation. If one covers the learning, patch it.
2. **UPDATE AN EXISTING UMBRELLA.** Read the "Existing skills" list above. If any one is a reasonable home, patch it as a labeled subsection — even if the fit isn't perfect.
3. **ADD A SUPPORT FILE** under an existing umbrella: `references/<topic>.md`, `templates/<name>.<ext>`, or `scripts/<name>.<ext>`. Add a one-line pointer in the parent SKILL.md.
   - **First list the existing `references/` files.** If one already covers this topic (same feature, ticket, bug, or pattern — even from a prior session), `Edit` it to fold in the new detail. Do NOT create a second file for the same topic.
   - **Name by topic, never by date.** Use `references/posthog-identity-relay.md`, not `references/posthog-identity-relay-2026-06-22.md`. A date suffix means you're logging a session, not building a reference — that's the wrong instinct. Timeless topic names are what let the next session find and update the file instead of duplicating it.
4. **CREATE A NEW UMBRELLA** — only as a last resort.

## How to patch an existing skill (CRITICAL)

When updating an existing skill (options 1 or 2), you MUST use the `Edit` tool, never `Write`. A `Write` call against an existing SKILL.md is a destructive rewrite and will damage the library.

Rules for patching:

1. **Use `Edit`, not `Write`.** Find a precise old_string and add new content next to it.
2. **Preserve the entire frontmatter exactly.** Never modify `name:`, `description:`, or `created_by:` of a skill that already exists, unless the user explicitly corrected the description in this session.
3. **Add as a labeled subsection at the END.** New learnings go as a new `## <Section Title>` block at the end of the file, not interleaved into existing prose.
4. **Never delete or shorten existing content.** Even if you think a section is redundant, leave it. The curator handles consolidation, not you.
5. **The file MUST grow, not shrink.** A correct patch produces a strictly longer file. If you find yourself shortening or restructuring, stop — you're doing too much.

Correct shape:

```
Edit(
  file_path="$SKILLS_DIR/<existing-skill>/SKILL.md",
  old_string="<last few lines of the existing file, verbatim>",
  new_string="<same last few lines>\n\n## <New Section Title>\n\n<new content>"
)
```

If the only thing you can think to do is rewrite the file from scratch, the right answer is `Nothing to save.` instead.

## Hard gate before creating a new skill

Before writing any new top-level skill directory, you MUST:

1. List 3 existing skills from the "Existing skills" snapshot above that you considered as the home for this learning.
2. State in one sentence each why it doesn't fit.
3. Only then create the new skill.

If you can't name 3 candidates, you haven't searched enough — patch an existing one instead. If the only good name for the new skill ends in `-eval`, `-verification`, `-review`, `-prep`, `-management`, `-design`, or names a specific tool/feature/PR/codename, it's a session artifact, not a class. Use a support file instead.

## Description format — REQUIRED

The `description:` field is what future agents read to decide whether to invoke the skill. It must contain at least one phrase the user would actually type, in quotes, OR start with "Use when the user says/asks ...".

❌ Bad (workflow summary, never matches a user utterance):
   `description: Enhance work items to be pickup-ready rather than just transcribing raw input`

✅ Good (user-phrasing trigger):
   `description: Prep daily tasks/WIP. Use when the user asks "make a WIP list", "prep today's tasks", "what should I work on next"`

If you can't write triggers as phrases the user would type, the skill isn't a class — it's a memory fact. Save it as memory instead.

## User-preference embedding

When the user complains about how you handled a task, update the skill that governs that task. Memory alone isn't enough.

## Protected skills (DO NOT edit)

- Anything under a plugin directory (`plugins/*/skills/<name>/`, including the plugin cache).
- Anything outside the skills directory printed at the top of this prompt.

If the only skills that need updating are protected, output `Nothing to save.` and stop.

## Do NOT capture (these become traps)

- Environment-dependent failures: missing binaries, fresh-install errors, path mismatches, "command not found", uninstalled packages.
- Negative claims about tools or features ("X tool is broken", "cannot use Y"). They harden into refusals long after the actual problem is fixed.
- Session-specific transient errors that resolved before the conversation ended. If retrying worked, the lesson is the retry pattern, not the original failure.
- One-off task narratives. A user asking "summarize today's market" is not a class of work.
- A user asking you something once. A class of task is something the user will do again.

If a tool failed because of setup state, capture the FIX (install command, env var) inside an existing setup/troubleshooting skill, never "this tool does not work" as a standalone.

## Memory format

Declarative facts, never imperatives. "User prefers concise responses" yes; "Always respond concisely" no. Imperatives override later requests.

## Frontmatter

Every new or modified skill includes `created_by: auto-improve`. When updating a skill with `created_by: user` or no `created_by`, do NOT overwrite that value and be conservative — patch obvious bugs only, never restructure.

```
---
name: <skill-name>
description: <see "Description format" above>
created_by: auto-improve
---
```

## Final check before writing

Answer these out loud before any Write call:

1. Did the user correct you, did a loaded skill turn out wrong, or did a class-level technique emerge? If none, output `Nothing to save.`
2. If creating a new skill: have I listed 3 existing skills I considered first?
3. Does the description contain a quoted user phrase or "Use when the user says..."?
4. Is the name class-level, not a session artifact?

If any answer is no, fix it before writing. Or output `Nothing to save.`
