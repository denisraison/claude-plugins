---
name: qa-scenarios
description: Generate user-impact QA test scenarios from a code change, in the style of a human QA tester probing real failure states. Use this whenever the user wants QA help on a commit, diff, branch, or PR; asks "what should I test here", "what would break", "what would a user hit"; wants to bootstrap or grow a failure-mode corpus for a repo; or is setting up per-commit / per-PR automated QA. Trigger even if the user does not say "QA" or "test" explicitly, as long as they are asking what could go wrong from a user's perspective for a code change. This skill is product-agnostic and reads the repo it runs in to learn the domain, so it works for any codebase.
---

# QA Scenarios

Generate the kind of test scenarios a sharp human QA tester would, the ones that come from knowing how *this specific product* gets into broken states, not from reading the diff in isolation. The diff tells you what changed; the domain knowledge tells you what a real user does around that change and how they break it.

The hard part of QA is not running tests, it is knowing which states are worth probing. A model reading a bare diff tests generically and produces noise. The same model, given the product's actual failure modes plus the change's intent, tests like someone who knows the product. This skill's whole job is to hold that domain knowledge next to the code and use it.

## Two modes

On invocation, work out which mode applies. Look for the domain file (see "The domain file" below) by walking up to the nearest `QA.md`.

- **No domain file, or the user is asking to set one up** -> **Bootstrap mode**. Build the corpus first.
- **Domain file exists and the user wants scenarios for a change** -> **Generate mode**.

If a domain file exists but is thin or stale for the area being changed, do a quick bootstrap pass for just that area before generating. Don't make the user choose a mode explicitly, infer it.

## The domain file

The domain knowledge lives next to the code, not in this skill. This is deliberate: the skill carries reusable procedure, the product carries its specific failure modes, discovered at runtime.

One corpus per *product*, not per repo. Many products span several repos (a frontend plus an API, or a multi-repo workspace), and the failures worth probing usually live at the boundary between them: "user clears the toggle in the web form -> the API must accept null as a no-op". A per-repo corpus splits exactly those cross-cutting, intent-dependent failures, which are the ones this skill adds the most value on. So state failure modes at the **user-flow / boundary level**, spanning repos where needed, and keep them in a single shared file.

Discovery is deterministic, so it's a script, not something to reason about. At the start of every run, run the bundled discovery script. It defaults to walking up from the current working directory, which is what you want:

```
scripts/gather-qa.sh
```

It walks up from the cwd, collects every `QA.md` (repo-level and workspace-level both), stops at `$HOME`/root, and prints each labelled by path, nearest first. Use its stdout as the corpus. If it prints `NO_QA_FILES_FOUND`, there's no corpus yet, go to Bootstrap mode. Do not hand-walk the tree; the model is unreliable at it (it stops at the first file) and the script is not. (Multi-repo workspaces with a manifest at their root can set `QA_WORKSPACE_MARKER` to that filename to bound the walk there instead.)

Use the files layered. The top one (workspace / product root) is primary and holds the cross-repo and boundary failures (a web-form -> api flow lives here, in neither repo alone). A nearer repo-level `QA.md`, if present, holds only failures genuinely local to that one repo; nearer = more specific. Most products have just the root one. A boundary/cross-repo failure must go in the workspace file, never a repo file (that's the per-repo trap). Fallback for small single-repo projects that prefer to inline it: a `## QA` section in a root `CLAUDE.md` / `AGENTS.md`.

If none exists and you're bootstrapping, create the shared `QA.md` at the product/workspace root unless the user prefers another location. Detect each repo's stack first (language, framework, test runner, how the app is run) from manifest files (`go.mod`, `package.json`, etc.) and the test setup, and record it at the top so later runs don't re-derive it.

### Domain file shape

```markdown
# QA — <product name>

## Stack
<language, framework, test runner, how it runs locally, how a user reaches it>

## Personas
<the kinds of user who hit this system, e.g. "new user with no data yet", "user mid-onboarding", "admin vs end-user">

## Failure modes
Each entry is a *stateful* situation, not an abstract category.
- <flow>: <the broken state> -> <what should happen / what must not happen>
  e.g. "OTP: code expires mid-registration -> resend works, no orphaned half-account"

## Triage rules
What is worth testing vs. skippable for this repo.
- e.g. "Changes touching only tests, docs, or generated code -> skip"
- e.g. "Anything touching the payment path -> always test the declined-charge and timeout cases"

## Corrections log
Lessons from scenarios that turned out wrong or useless. Append here; never delete.
- <date>: <the dud scenario> -> <the rule that prevents it next time>
```

Keep entries concrete and stateful. "Test edge cases" teaches nothing. "User lands on dashboard before their first record syncs -> empty state must not 500" is actionable and verifiable. Prefer the second every time.

## Bootstrap mode

Goal: produce a domain file with enough teeth that generate mode stops producing generic scenarios. Do it in two passes, interview first, then code.

### Pass 1: interview

Ask the user, a few at a time (use interactive option buttons if available, otherwise short questions), enough to fill Personas and the first Failure modes. Good opening questions:
- Who are the different kinds of user that hit this system?
- What's a flow where you've actually seen things break, or where you hold your breath on deploy?
- For that flow: what partial / interrupted / stale states can a user get into? (half-completed signup, expired token, webhook that never arrived, permission revoked mid-session, etc.)
- What's a change that looks safe in the diff but isn't, for this product?

Drive the interview from the product's reality, not a generic checklist. Draft each failure mode back to the user in the stateful format and let them correct, they react, you write. This is the point: the user should not be authoring prose, they should be saying yes / no / also-this while you record.

### Pass 2: read the code

After the interview, read the repo to fill gaps the user didn't mention:
- entry points (routes, handlers, queue consumers, CLI commands) -> each is a place a user-equivalent reaches the system
- state machines, status enums, nullable/optional fields -> sources of partial states
- external calls (payments, messaging, third-party APIs) -> sources of "the call never came back" failures
- existing tests -> what's already covered, so you don't duplicate

Propose the additional failure modes you inferred, again for the user to confirm, then write the domain file.

Stop when the file covers the flows the user actually cares about. Don't try to be exhaustive on day one; the corrections log grows it over time.

## Generate mode

Inputs: a change (commit, diff, branch, or PR) and the domain file.

### Step 1: get the change with intent

A bare diff produces worse scenarios than a diff plus a one-line statement of what the change is *meant* to do. If the intent isn't obvious from the commit message or PR description, ask the user for one line: "what's this change supposed to do?" This single line measurably improves output, don't skip it.

### Step 2: triage

Apply the domain file's triage rules. If the change is skippable (tests/docs/generated only, no runtime behaviour change), say so plainly and stop, a clear "skip, nothing user-facing changed" is a valid and valuable output. Don't manufacture scenarios for changes that don't warrant them.

### Step 3: generate scenarios

For changes worth testing, produce scenarios in this format:

```
## <short label for the change>

### Test it
- <persona + stateful setup> -> <action> -> <what must happen / must not happen>
  why: <which failure mode or new risk this covers>

### Skip
- <anything in the change that doesn't need a scenario, with one-line reason>
```

Rules for good scenarios:
- Start from the user's situation, not the code. Lead with state ("fresh account, no data yet"), then action, then expected outcome.
- Cross-reference the domain file's failure modes. A new change near a known failure mode should test that mode.
- Each scenario names *why* it exists. If you can't state why, cut it.
- Prefer a handful of sharp scenarios over a long generic list. Volume is the failure mode of generic QA.
- Mark which scenarios are unit-testable now vs. which need browser / integration / manual, so the user knows what's cheap.

### Step 4: grow the corpus

This is what makes the skill improve instead of repeating itself. When the user reacts to the scenarios:
- A scenario they call useless or impossible -> append it to the **Corrections log** with the rule that would have prevented it.
- A failure mode they mention that wasn't in the file -> add it to **Failure modes**.
- A new triage rule they state -> add it to **Triage rules**.

Make these edits yourself, as a side effect of the conversation. The user should never have to open and hand-edit the file; reacting to your output is how they teach it. Write to the right level: a cross-repo or boundary failure goes in the workspace-root `QA.md`; a failure genuinely local to one repo goes in that repo's `QA.md` (creating it only if a repo-local mode actually warrants one).

## Output discipline

This skill produces scenarios for a human to act on, or to feed to an execution layer. Keep output tight: the scenario list and, if you changed the domain file, a one-line note of what you added. Don't pad with QA theory or restate the diff.
