#!/usr/bin/env bash
# context-gardener recurring gate (macOS / Linux).
# Wire this to a Claude Code SessionStart hook. It fires at most once per
# INTERVAL_DAYS: when due it stamps the run time and injects an instruction
# telling the interactive agent to run context-gardener in REPORT mode over the
# ~/.claude context surface. Silent (exit 0, no output) otherwise.
# Report-only by design; it never applies changes. Requires python3 (for JSON).

set -euo pipefail
interval_days=7
claude="$HOME/.claude"
state="$claude/state/context-gardener-last-run.txt"
reports="$claude/context-gardener-reports"
now_epoch=$(date +%s)

# Due check: due if no stamp or the stamp is >= interval old.
if [ -f "$state" ]; then
  last=$(cat "$state" 2>/dev/null || echo 0)
  if [ -n "${last:-}" ] && [ "$last" -gt 0 ] 2>/dev/null; then
    if [ $(( (now_epoch - last) / 86400 )) -lt "$interval_days" ]; then exit 0; fi
  fi
fi

# Stamp now (epoch), so the hook never fires more than once per interval.
mkdir -p "$(dirname "$state")" "$reports"
printf '%s' "$now_epoch" > "$state"
report="$reports/$(date +%Y-%m-%d).md"

python3 - "$report" "$interval_days" <<'PY'
import json, sys
report, interval = sys.argv[1], sys.argv[2]
msg = (
  f"SCHEDULED CONTEXT HYGIENE ({interval}-day cadence): it has been at least {interval} days "
  "since the last context-gardener sweep of the ~/.claude context surface.\n\n"
  "Run the context-gardener skill now in REPORT mode only (read-only; do not edit, rename, "
  "delete, or apply anything). Discover and audit the context surface: the global CLAUDE.md, any "
  "@-included profile or house-style docs, AGENTS.md / GEMINI.md if present, and the memory index "
  f"and its files if present. Produce the ranked findings report and write it to: {report}\n\n"
  "Then tell the user in one line that the scheduled context-gardener sweep ran, where the report "
  "is, and that they can review it and ask you to apply fixes (nothing has been changed). If the "
  "user is clearly mid-task, run the sweep after their immediate request. Do not apply any changes "
  "in this run."
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": msg}}))
PY

exit 0
