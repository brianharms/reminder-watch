#!/usr/bin/env bash
# install.sh — Install Reminders Bridge for Claude Code.
#
# Copies scripts and skill to ~/.claude/. That's it.
# No daemon, no manifest, no config prompts — config happens on first run.

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills/reminders"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     Reminders Bridge — Installer     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Preflight checks ────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  echo "✗ This only works on macOS (needs AppleScript + Apple Reminders)."
  exit 1
fi

if ! command -v claude &>/dev/null && [[ ! -f "${HOME}/.local/bin/claude" ]]; then
  echo "✗ Claude Code CLI not found."
  echo "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

echo "✓ Prerequisites OK"
echo ""

# ── Create directories ──────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"
mkdir -p "$SKILLS_DIR"

# ── Copy scripts ────────────────────────────────────────────────────────────
echo "Installing scripts to ${CLAUDE_DIR}/"

cp scripts/reminder-check.sh  "$CLAUDE_DIR/reminder-check.sh"
cp scripts/reminder-output.sh "$CLAUDE_DIR/reminder-output.sh"
chmod +x "$CLAUDE_DIR/reminder-check.sh"
chmod +x "$CLAUDE_DIR/reminder-output.sh"

echo "  ✓ reminder-check.sh"
echo "  ✓ reminder-output.sh"

# ── Install skill ───────────────────────────────────────────────────────────
echo ""
echo "Installing Claude Code skill to ${SKILLS_DIR}/"
cp skill/SKILL.md "$SKILLS_DIR/SKILL.md"
echo "  ✓ SKILL.md (/reminders command)"

# ── Create seen file if needed ──────────────────────────────────────────────
touch "$CLAUDE_DIR/reminder-seen.txt"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo ""
echo "✓ Installed!"
echo ""
echo "Next steps:"
echo ""
echo "  1. Open Apple Reminders and create two lists:"
echo "     • Claude Inbox"
echo "     • Claude Output"
echo ""
echo "  2. Make sure iCloud Reminders sync is enabled on your iPhone"
echo ""
echo "  3. Open Claude Code and run:"
echo "     /loop 5m /reminders"
echo ""
echo "  4. First run will ask where your projects folder is"
echo ""
