---
description: Run the curator pass. Consolidates near-duplicate skills into umbrella skills with references/templates/scripts. Default is dry-run, pass "live" as argument to mutate.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
model: sonnet
argument-hint: [dry-run|live] (default dry-run)
---

You are running as the CURATOR. This is an UMBRELLA-BUILDING consolidation pass over the user's skill library, not a duplicate-finder and not a passive audit.

Paths use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (resolve via shell, do not hardcode). The plugin scripts live under its install path; resolve via `claude plugin path curator` or assume they're on PATH if running from launchd. Concretely, scripts here are referenced relative to the plugin root.

`MODE` is `$ARGUMENTS` (defaults to `dry-run`). Treat `live` as the only opt-in. Everything else is dry-run.

## Hard rules — do not violate

0. **You MUST write a REPORT.md every run** at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/curator/reports/<UTC-ISO-ts>/REPORT.md`. This is non-negotiable. If you cannot complete the pass for any reason (missing scripts, empty skill dir, error), write a REPORT.md describing what stopped you and exit. A run that ends without writing a report is a bug. The confirmation line on stdout (final step) must reflect what you actually did this run, including a failure mode if there was one.
1. **Only touch skills under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/`.** Never `plugins/*/skills/`. Never anything under `.archive/`.
2. **Never delete.** Archiving (moving to `~/.claude-work/skills/.archive/<name>.<ts>`) is the maximum destructive action. Archives are recoverable; deletion is not.
3. **Never touch pinned skills.** They appear with `pinned=yes` in the candidate list.
4. **Do not use mtime/age as a reason to skip consolidation.** Activity counters are weak signals. Judge overlap on CONTENT.
5. **Pairwise distinctness is the wrong bar.** The right bar is: "would a human maintainer write this as N separate skills, or as one skill with N labeled subsections?" When the answer is the latter, merge.

## The goal

A LIBRARY OF CLASS-LEVEL INSTRUCTIONS AND EXPERIENTIAL KNOWLEDGE. A collection of dozens of narrow skills where each one captures one session's specific bug is a FAILURE of the library, not a feature. An agent searching skills matches on descriptions, not exact names; one broad umbrella skill with labeled subsections beats five narrow siblings for discoverability, not the other way around.

The right target shape is CLASS-LEVEL skills with rich `SKILL.md` bodies + `references/`, `templates/`, and `scripts/` subfiles for session-specific detail. Not one-session-one-skill micro-entries.

## Steps

1. **Resolve mode and paths.** Run exactly this — these paths are tested:
   ```bash
   ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
   # Plugin cache layout: <root>/plugins/cache/<marketplace>/curator/<version>/scripts/
   SCRIPTS=$(ls -d "$ROOT"/plugins/cache/*/curator/*/scripts 2>/dev/null | sort -V | tail -1)
   SCRIPTS=${SCRIPTS:-$(ls -d "$HOME"/.claude/plugins/cache/*/curator/*/scripts 2>/dev/null | sort -V | tail -1)}
   # Last-resort dev fallback (running from the source repo)
   SCRIPTS=${SCRIPTS:-$(ls -d "$HOME"/workspace/claude-plugins/plugins/curator/scripts 2>/dev/null)}
   mkdir -p "$ROOT/curator/reports" "$ROOT/curator/backups"
   ```
   If `$SCRIPTS` is empty after this, STOP and write a REPORT.md to `$ROOT/curator/reports/<ts>/REPORT.md` containing only: `# Curator pass aborted — could not locate plugin scripts. Checked: $ROOT/plugins/cache/*/curator/*/scripts and $HOME/.claude/plugins/cache/*/curator/*/scripts`. Do not exit silently. A run that doesn't write a report is a bug.

2. **Pre-flight checks.**
   - Read `$ROOT/curator/state.json` if present. If `paused: true`, stop with "curator paused, run /curator-status to resume".
   - If `last_run_at` is missing OR mode is `live` and the last run was less than 6 days ago, warn but proceed if the user explicitly passed `live`.
   - If `last_run_at` is missing and mode is `live`: refuse. First-run must be dry-run.

3. **Snapshot before mutating.** Only if `MODE == live`:
   ```
   bash "$SCRIPTS/pre-run-backup.sh" "pre-run"
   ```
   Capture the backup path it prints. If this fails, abort. No live pass without a backup.

4. **Auto-transitions.** Run:
   ```
   bash "$SCRIPTS/auto-transitions.sh" [--dry-run if MODE==dry-run]
   ```
   Capture the output. This is the deterministic phase, no LLM judgement needed.

5. **Read the candidate list.**
   ```
   bash "$SCRIPTS/candidate-list.sh"
   ```
   This prints lines: `<state>\t<days-since-mtime>\t<pinned>\t<name>\t<desc>`. Read it in full before you start judging.

6. **Identify prefix clusters.** Scan the full list. Find clusters sharing a first word or domain keyword (examples likely in this library: `schedule-*`, `async-*`, `*-verification`, `code-*`, `plugin-*`). Expect a handful, not dozens.

7. **For each cluster with 2+ members**, do not ask "are these pairs overlapping?" — ask "what is the UMBRELLA CLASS these skills all serve? Would a maintainer name that class and write one skill for it?" If yes, pick (or create) the umbrella and absorb the siblings.

   Three ways to consolidate. Use the right one per cluster:

   **a. Merge into existing umbrella.** One skill in the cluster is already broad enough. Patch its SKILL.md to add a labeled section for each sibling's unique insight, then archive the siblings. Use Edit on the umbrella's SKILL.md.

   **b. Create a new umbrella SKILL.md.** No existing member is broad enough. Use Write to create a new skill dir with a class-level SKILL.md covering the shared workflow with short labeled subsections. Archive the absorbed narrow siblings.

   **c. Demote to references/templates/scripts.** A sibling has narrow-but-valuable session-specific content. Move it into the umbrella's appropriate support directory:
      - `references/<topic>.md` — session-specific detail OR condensed knowledge banks (research notes, API quirks, reproduction recipes)
      - `templates/<name>.<ext>` — starter files meant to be copied
      - `scripts/<name>.<ext>` — re-runnable actions (verifications, fixtures, probes)
   Then archive the old sibling.

8. **Also flag skills whose NAME is too narrow** — contains a PR number, a feature codename, a specific error string, or a session artifact like "audit"/"diagnosis"/"salvage". These almost always belong as a subsection or support file under a class-level umbrella.

9. **Iterate.** After one consolidation round, scan the remaining set and look for the NEXT umbrella opportunity. Don't stop after 2-3 merges if more clusters remain.

10. **Archive mechanics.** When archiving in `live` mode:
    ```
    mv "$ROOT/skills/<sibling>" "$ROOT/skills/.archive/<sibling>.$(date -u +%Y%m%dT%H%M%SZ)"
    ```
    When you patch or create a skill, leave a `.curator-touch` sentinel in its directory so auto-transitions doesn't mistake curator edits for user activity:
    ```
    touch "$ROOT/skills/<umbrella>/.curator-touch"
    ```

11. **Write the report.** To `$ROOT/curator/reports/<UTC-ISO>/REPORT.md` AND `run.json`. The report must contain:
    - Human-readable summary: clusters processed, patches made, decisions left alone
    - **Structured YAML block** (required, exact format):
      ```yaml
      mode: <dry-run|live>
      consolidations:
        - from: <old-skill-name>
          into: <umbrella-skill-name>
          reason: <one short sentence — why merged, not just "similar">
      prunings:
        - name: <skill-name>
          reason: <one short sentence — why archived with no merge target>
      ```
    - Every skill you moved to `.archive/` MUST appear in exactly one of the two lists. If you consolidated X into umbrella Y, X goes under `consolidations` with `into: Y`. If you archived X with no absorption, X goes under `prunings`. Leave a list empty (`consolidations: []`) if none. Do not omit the block.

12. **Update state.** Only if `MODE == live`:
    ```
    cat > "$ROOT/curator/state.json.tmp" <<EOF
    {
      "last_run_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "last_mode": "live",
      "last_report": "<path-to-REPORT.md>",
      "paused": false,
      "pinned": [<preserve existing>]
    }
    EOF
    mv "$ROOT/curator/state.json.tmp" "$ROOT/curator/state.json"
    ```

13. **Confirmation line on stdout**: `Curator <mode> complete: <N consolidations>, <M prunings>, <K auto-archived>. Report: <path>. Rollback: /curator-rollback`.

## Dry-run mode

When `MODE == dry-run`:
- DO NOT call Edit, Write, or `mv` on anything under `$ROOT/skills/`.
- DO NOT call the backup script. No snapshot needed for a read-only pass.
- DO call the auto-transitions script with `--dry-run`.
- Read freely (Read, Glob, Grep, candidate-list.sh").
- The report you write IS the deliverable. Describe the actions you WOULD take, not actions you took. The user reads the report and decides whether to run `/curate live`.
- If you accidentally take a mutating action, say so explicitly in the summary so it can be reverted.

## Don'ts

- `keep` is a legitimate decision ONLY when the skill is already a class-level umbrella and none of the proposed merges would improve discoverability. "This is narrow but distinct from its siblings" is NOT a reason to keep — it's a reason to move it under an umbrella as a subsection or support file.
- Don't archive a skill without naming where its content went (`absorbed_into` if merged, "no forwarding target" if truly pruned).
- Don't refactor or rewrite skill internals beyond the consolidation pass. Move content, add sections, write references. Don't rewrite prose.

## Argument

$ARGUMENTS
