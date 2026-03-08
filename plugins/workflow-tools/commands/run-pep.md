---
description: Generate a headless claude command to autonomously implement a PEP wave. Usage - /run-pep [PEP file or number] [wave number]
arguments:
  - name: pep
    description: PEP file path or number (e.g. "003" or "docs/PEP-003-auth.md")
    required: false
  - name: wave
    description: Wave number to implement (defaults to first incomplete wave)
    required: false
---

## Find the PEP

1. If `$ARGUMENTS` includes a file path, use it directly
2. If it includes a number, glob for `**/docs/PEP-{number}*.md`
3. If no arguments, glob for `**/docs/PEP-*.md` and pick the most recently modified one with status "In Progress" or "Draft"

Read the PEP file.

## Identify the Wave

1. If a wave number was specified, use that wave
2. Otherwise, find the first wave with unchecked tasks (`- [ ]`)

Extract from the PEP:
- The wave title and full content (requirements, changes, gate criteria)
- The project's test/build commands if mentioned anywhere in the PEP

## Activate the Gate Hook

Create a `.pep-gate` file in the project root with the PEP path and wave info. This activates the plugin's built-in Stop hook, which will block Claude from stopping until all gate criteria pass.

```bash
echo "[PEP file path] wave [N]" > .pep-gate
```

Tell the user: "Created `.pep-gate` to activate the gate-keeper Stop hook. Claude will not be able to stop until all gate criteria pass. Delete `.pep-gate` to deactivate."

## Generate the Command

Output two options: a single-shot command and a fresh-context loop. The user picks whichever fits.

### Option A: Single shot with gate hook (keeps context, good for straightforward waves)

The plugin's Stop hook will automatically verify gates before allowing Claude to stop. When all gates pass, Claude deletes `.pep-gate` and exits cleanly.

```bash
claude -p "$(cat <<'PROMPT'
Read [PEP file path] and implement [Wave N: title].

Requirements from the PEP:
[paste the wave's requirements section]

Gate criteria:
[paste the wave's gate section]

Instructions:
- Implement all requirements listed in the wave
- Run the deterministic gate checks (test suites, type checks, linters) after each significant change
- When all requirements are met and gate criteria pass:
  1. Update the PEP file: check off completed tasks (`- [x]`), update wave status. If you made decisions not covered by the PEP or fixed issues the gate caught, add them to the wave as notes so the PEP stays the source of truth.
  2. Run /simplify to review the changed code for reuse, quality, and efficiency. Fix any issues it finds.
  3. Commit your work with a message referencing the PEP and wave
- Before stopping, verify every gate criterion yourself. If any gate fails, fix it before stopping.
- When all gates pass, delete the .pep-gate file then stop.
PROMPT
)" \
  --allowedTools \
    "Read" "Edit" "Write" "Glob" "Grep" \
    "Bash(npm *)" "Bash(npx *)" "Bash(node *)" \
    "Bash(go *)" "Bash(cargo *)" "Bash(python *)" "Bash(pip *)" \
    "Bash(make *)" "Bash(bun *)" \
    "Bash(git diff *)" "Bash(git status *)" "Bash(git log *)" \
    "Bash(git add *)" "Bash(git commit *)" \
    "Bash(rm .pep-gate)" \
    "Bash(ls *)" "Bash(mkdir *)" "Bash(cat *)" "Bash(test *)" \
  --max-turns 50
```

### Option B: Fresh-context loop (restarts with clean context each attempt, better for complex waves)

```bash
#!/usr/bin/env bash
set -euo pipefail

PEP="[PEP file path]"
MAX_ATTEMPTS=5

echo "[PEP file path] wave [N]" > .pep-gate

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "=== Attempt $attempt/$MAX_ATTEMPTS ==="

  result=$(claude -p "$(cat <<PROMPT
Read $PEP and implement [Wave N: title].

[paste the wave's requirements and gate sections]

Instructions:
- Check git log and diff to see what has been done in previous attempts
- Implement any remaining requirements
- Run deterministic gate checks after each significant change
- When all requirements are met and gates pass:
  1. Update the PEP file: check off completed tasks (\`- [x]\`), update wave status. If you made decisions not covered by the PEP or fixed issues the gate caught, add them to the wave as notes so the PEP stays the source of truth.
  2. Run /simplify to review the changed code for reuse, quality, and efficiency. Fix any issues it finds.
  3. Commit with a message referencing the PEP and wave
- If all gates pass, delete .pep-gate and output GATES_PASSED as your final line
- If you cannot get all gates passing, commit what you have and output GATES_FAILED as your final line
PROMPT
  )" \
    --allowedTools \
      "Read" "Edit" "Write" "Glob" "Grep" \
      "Bash(npm *)" "Bash(npx *)" "Bash(node *)" \
      "Bash(go *)" "Bash(cargo *)" "Bash(python *)" "Bash(pip *)" \
      "Bash(make *)" "Bash(bun *)" \
      "Bash(git diff *)" "Bash(git status *)" "Bash(git log *)" \
      "Bash(git add *)" "Bash(git commit *)" \
      "Bash(rm .pep-gate)" \
      "Bash(ls *)" "Bash(mkdir *)" "Bash(cat *)" "Bash(test *)" \
    --max-turns 40 \
    --output-format text 2>&1)

  echo "$result" | tail -5

  if echo "$result" | grep -q "GATES_PASSED"; then
    echo "=== Wave complete ==="
    exit 0
  fi

  echo "Gates did not pass, retrying with fresh context..."
done

rm -f .pep-gate
echo "=== Failed after $MAX_ATTEMPTS attempts ==="
exit 1
```

Adapt the `--allowedTools` list based on what the PEP actually needs. Remove tools for languages not used. Add specific tools if the PEP mentions them.
