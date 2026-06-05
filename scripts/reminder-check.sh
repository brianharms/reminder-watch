#!/usr/bin/env bash
# reminder-check.sh — Query Apple Reminders for new tasks and flagged output.
#
# Part of Reminders Bridge (https://github.com/brianharms/reminder-watch)
#
# Reads "Claude Inbox" for new (unseen) reminders and "Claude Output" for
# flagged items that need the user's attention. Outputs pipe-delimited lines:
#
#   NEW|title|notes        — A new task from the inbox
#   FLAGGED|title|notes    — A flagged item from output needing user input
#
# Exit codes:
#   0 — Items found (new and/or flagged)
#   1 — Nothing new

set -euo pipefail

SEEN_FILE="${HOME}/.claude/reminder-seen.txt"
touch "$SEEN_FILE"

# ── Query Claude Inbox for incomplete reminders ─────────────────────────────
INBOX=$(osascript 2>/dev/null <<'APPLESCRIPT'
tell application "Reminders"
    set output to ""
    try
        repeat with r in (reminders of list "Claude Inbox" whose completed is false)
            set rid to id of r
            set rname to name of r
            set rnotes to body of r
            if rnotes is missing value then set rnotes to ""
            set output to output & rid & "	" & rname & "	" & rnotes & linefeed
        end repeat
    end try
    return output
end tell
APPLESCRIPT
)

# ── Filter new items against seen file ──────────────────────────────────────
FOUND=0
NEW_ITEMS=""

if [ -n "$INBOX" ]; then
    while IFS=$'\t' read -r RID RNAME RNOTES; do
        [ -z "$RID" ] && continue
        if ! grep -qxF "$RID" "$SEEN_FILE" 2>/dev/null; then
            # Track this reminder so we don't process it again
            echo "$RID" >> "$SEEN_FILE"
            # Mark complete in Reminders to prevent re-processing
            osascript 2>/dev/null <<ENDSCRIPT
tell application "Reminders"
    try
        repeat with r in (reminders of list "Claude Inbox" whose completed is false)
            if id of r is "${RID}" then
                set completed of r to true
                exit repeat
            end if
        end repeat
    end try
end tell
ENDSCRIPT
            NEW_ITEMS="${NEW_ITEMS}NEW|${RNAME}|${RNOTES}
"
            FOUND=1
        fi
    done <<< "$INBOX"
fi

# ── Query Claude Output for flagged items (questions needing user input) ────
FLAGGED=$(osascript 2>/dev/null <<'APPLESCRIPT'
tell application "Reminders"
    set output to ""
    try
        repeat with r in (reminders of list "Claude Output" whose completed is false)
            if flagged of r then
                set rname to name of r
                set rnotes to body of r
                if rnotes is missing value then set rnotes to ""
                set output to output & "FLAGGED|" & rname & "|" & rnotes & linefeed
            end if
        end repeat
    end try
    return output
end tell
APPLESCRIPT
)

if [ -n "$FLAGGED" ]; then
    FOUND=1
fi

# ── Output results ──────────────────────────────────────────────────────────
if [ -n "$NEW_ITEMS" ]; then
    printf '%s' "$NEW_ITEMS"
fi
if [ -n "$FLAGGED" ]; then
    printf '%s' "$FLAGGED"
fi

# Exit 1 if nothing found (skill uses this for silent return)
if [ "$FOUND" -eq 0 ]; then
    exit 1
fi
exit 0
