---
name: reminders
description: Check and act on Apple Reminders — reads Claude Inbox for pending tasks and Claude Output for results. Automatically dispatches agents for new inbox items. Use when user says /reminders, "check reminders", "what came in", or to start the watcher via /loop.
user_invocable: true
---

# Reminders Bridge

Check Apple Reminders for new tasks and dispatch agents to work on them.

## Step 1: Config Check

Check if `~/.claude/reminders-config.sh` exists.

**If it exists:** Source it to get the `PROJECTS_DIR` variable. Continue to Step 2.

**If it does NOT exist:**
- First, check if this skill was invoked via `/loop`. If so, print this message and stop:
  > Run `/reminders` once to configure your projects folder, then start the loop.
- If invoked directly, ask the user: **"Where's your projects folder?"**
  - Accept natural language (e.g., "it's in myProjects on the desktop", "~/code", "the projects folder on my desktop")
  - Resolve the response to an absolute path (expand `~`, interpret natural language like "on the desktop" → `~/Desktop/...`)
  - Verify the path exists by running `ls` on it
  - If the path doesn't exist, tell the user and ask again
  - Once valid, write the config file:
    ```bash
    echo 'PROJECTS_DIR="/resolved/absolute/path"' > ~/.claude/reminders-config.sh
    ```
  - Continue to Step 2

## Step 2: Run the Check Script

Run this exact command:

```bash
~/.claude/reminder-check.sh
```

This script:
- Queries "Claude Inbox" for incomplete reminders
- Filters out already-seen IDs (tracked in `~/.claude/reminder-seen.txt`)
- Marks new reminders as complete in Reminders (prevents re-processing)
- Queries "Claude Output" for flagged items (questions needing user input)
- Outputs pipe-delimited lines: `NEW|title|notes` or `FLAGGED|title|notes`
- Returns exit code 1 if nothing new (no output)

**If exit code is 1 (nothing new):** Say nothing. Return silently. Do NOT output "nothing new" or any status message — just stop.

## Step 3: Handle Results

**For each `NEW|title|notes` line:**

1. Run `ls` on the `PROJECTS_DIR` to get the list of existing project folder names.
2. Evaluate the task title and notes against the folder names. Use your judgment:
   - **Clear match** — Use that folder (e.g., "work on mac caps" → `mac-caps/`)
   - **Ambiguous but close** — Lean toward the existing project when the name is similar
   - **No match** — Create a new folder in `PROJECTS_DIR` with a concise kebab-case name derived from the task title
3. Dispatch a background Agent:

```
Agent tool:
  description: "Reminder: [first 3 words of title]"
  run_in_background: true
  prompt: |
    You are working autonomously on a task sent via Apple Reminders.

    TASK TITLE: [title]
    TASK NOTES: [notes]
    PROJECT DIR: [resolved absolute path to project folder]

    INSTRUCTIONS:
    1. cd into the project directory.
    2. If CLAUDE.md exists, read it and follow its conventions.
    3. If SESSION_LOG.md exists, read the most recent entry for context.
    4. Do the work. Build, prototype, scaffold. Be bold but follow existing patterns.

    GUARDRAILS:
    - Do NOT delete files
    - Do NOT git push or deploy
    - Do NOT post to external APIs
    - Do NOT modify other projects outside PROJECT DIR

    WHEN DONE:
    1. Run: ~/.claude/reminder-output.sh "[project-name] Done — summary" "Details of what was built"
       Or if you need input: ~/.claude/reminder-output.sh "[project-name] Question — what you need" "Context" "true"
    2. Append to SESSION_LOG.md with the date and what you did.
```

**For each `FLAGGED|title|notes` line:** Display it prominently — these are questions from agents that need user input.

## Step 4: Report

- If agents were dispatched: "Dispatched agent for: [title] → [project-folder]" (one line per task)
- If flagged items exist: "Needs your input: [title]"
- If nothing at all: say nothing (silent return)
