---
name: paseo
description: Drive Paseo, Denis's agent app, from inside a session. Open a terminal tab in the current workspace and run something in it (a dev server, a TUI, an interactive login), read what's on screen, start or message another agent, and open code in tuicr when Denis reviews it himself. Use when he says "let me review", "I'll review it", "open the diff", "show me the diff", "open it in tuicr", "done, I left comments", "open a terminal", "run X in a tab", "start the dev server", "spin up an agent", "hand this to another agent". Not for reviews he asks you to do ("review PR 412 for me"): those are a normal code review.
---

Inspired by agavra/tuicr: skills/tuicr/SKILL.md

Every agent Paseo starts gets `PASEO_WORKSPACE_ID` and `PASEO_AGENT_ID` in its env. If `PASEO_WORKSPACE_ID` is empty you're not in Paseo: give Denis the command to run himself (for a review, the same tuicr command and keys as below). Reading his tuicr comments works either way.

## Terminals

```bash
paseo terminal ls --json                            # name, id, cwd of this workspace's tabs
id=$(paseo terminal create --workspace "$PASEO_WORKSPACE_ID" --cwd "$PWD" --name <name> --json | jq -r .id)
paseo terminal send-keys "$id" "<command>" Enter    # types the command and presses Enter
paseo terminal capture "$id"                        # what's on screen now; -S for scrollback
paseo terminal kill "$id"                           # only when Denis is done with it
```

- The terminal appears as a tab in his workspace. Name it for what runs there (`review`, `dev-server`) and tell him the tab name.
- Reuse a tab with the same name only if `capture` shows a shell prompt. If something is still running in it (an old tuicr, a server), keys would go into that program: make a new tab instead.
- Long-running commands: `capture` is a snapshot, so poll it every few seconds until the ready line shows (Vite prints `Local: http://localhost:<port>`), up to about a minute. Report the URL from the output, not the port you expected; servers move to the next port when theirs is busy. If it errors, show him the error lines.
- Leave servers running when you're done unless he says otherwise.

## Denis reviews code in tuicr

When he says "let me review", "open the diff", "I'll look at it" or "open it in tuicr":

1. Scope. Uncommitted work (anything he says "before we commit" about): `tuicr -w`, which includes new untracked files. Committed work on a branch: `tuicr -r main..HEAD`. Both: `tuicr -r main..HEAD -w`. A PR: `tuicr pr <number>`. If there's both uncommitted and committed work and his words don't pick, ask.
2. Open it in a `review` tab (above) and tell him it's there. Keys: `c` comment, `v` select a range, `r` mark file reviewed, `:wq` save and quit. Comments persist after quitting.
3. Wait for him to say he's done. Don't comment on your own patch, and don't start fixing yet.
4. Read his comments:
   ```bash
   tuicr review list --repo "$(git rev-parse --show-toplevel)"
   tuicr review comments --repo "$(git rev-parse --show-toplevel)" --session <slug>
   ```
   Take the session whose slug matches the scope you opened (`staged-and-unstaged` for `-w`, the commit range for `-r`), most recent `updated_at`. Ask only if that still leaves more than one.
5. Work through them as a numbered list, one fix per comment, and say which you did and which you're pushing back on.

If he asks you to review and also write your findings into tuicr, add them with `tuicr review add --session <slug> --username agent --target-file <path> --line <n> "<comment>"`.

## Other agents

Only when Denis asks; don't fan out on your own.

```bash
paseo run --no-wait --title "<short name>" "<task>"   # new agent tab in this workspace
paseo send <agent-id> "<message>"                      # message an existing agent
paseo wait <agent-id>                                  # block until it's idle
paseo logs <agent-id>                                  # what it did
paseo ls                                               # agents and their ids
```

`paseo run` defaults to this workspace. For separate work on a branch use `--new-workspace worktree --new-branch <name>`.
