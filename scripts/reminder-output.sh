#!/usr/bin/env bash
# reminder-output.sh — Write a reminder to the "Claude Output" list.
#
# Part of Reminders Bridge (https://github.com/brianharms/reminder-watch)
#
# Usage: reminder-output.sh "Title" "Body text" [true|false]
#
# Arguments:
#   $1 — Title (required)
#   $2 — Body (required)
#   $3 — Flag as urgent (optional, default "false"). Sets priority to 1.
#
# Called by dispatched agents to report results back to the user's phone.

set -euo pipefail

TITLE="${1:-}"
BODY="${2:-}"
FLAGGED="${3:-false}"

if [[ -z "$TITLE" ]]; then
  echo "Error: title is required." >&2
  exit 1
fi

if [[ -z "$BODY" ]]; then
  echo "Error: body is required." >&2
  exit 1
fi

# Escape double quotes and backslashes for AppleScript string literals
escape_as() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

TITLE_ESC="$(escape_as "$TITLE")"
BODY_ESC="$(escape_as "$BODY")"

if [[ "$FLAGGED" == "true" ]]; then
  PRIORITY_LINE="set priority of newReminder to 1"
else
  PRIORITY_LINE=""
fi

SCRIPT=$(cat <<APPLESCRIPT
tell application "Reminders"
  set targetList to list "Claude Output"
  set newReminder to make new reminder at end of reminders of targetList
  set name of newReminder to "${TITLE_ESC}"
  set body of newReminder to "${BODY_ESC}"
  ${PRIORITY_LINE}
end tell
APPLESCRIPT
)

if osascript -e "$SCRIPT" 2>/dev/null; then
  echo "Reminder created: ${TITLE}"
else
  echo "Error: osascript failed to create reminder." >&2
  exit 1
fi
