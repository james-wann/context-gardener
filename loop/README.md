# Running context-gardener on a loop

The value of the skill compounds when you stop having to remember to run it. This wires it to a Claude Code **SessionStart hook** that fires at most once per interval (7 days by default), runs the audit in **report mode** (read-only), and writes you a dated findings file. It never applies changes on its own; you review the report and decide.

## How it works

- `context-gardener-report.ps1` (Windows) and `context-gardener-report.sh` (macOS/Linux) are gate scripts.
- Each checks a timestamp file (`~/.claude/state/context-gardener-last-run.txt`). If under the interval, it stays silent. If due, it stamps the clock and prints a SessionStart instruction telling your interactive agent to run context-gardener in report mode over your `~/.claude` context surface and save the report to `~/.claude/context-gardener-reports/<date>.md`.
- It stamps on fire, so it can never run more often than once per interval, even across multiple sessions.

## Set it up

1. Copy the script for your platform somewhere stable, e.g. `~/.claude/hooks/`.
2. On macOS/Linux, make it executable: `chmod +x ~/.claude/hooks/context-gardener-report.sh` (needs `python3` for JSON output).
3. Add a SessionStart hook to your user settings at `~/.claude/settings.json`, merging with any existing hooks:

**Windows:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\<you>\\.claude\\hooks\\context-gardener-report.ps1\"",
            "timeout": 20,
            "statusMessage": "Context hygiene check"
          }
        ]
      }
    ]
  }
}
```

**macOS/Linux:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/context-gardener-report.sh",
            "timeout": 20,
            "statusMessage": "Context hygiene check"
          }
        ]
      }
    ]
  }
}
```

4. Change the cadence by editing `$intervalDays` / `interval_days` at the top of the script.

## Notes

- It fires on your first session after the interval elapses, not at an exact clock time. That is the trade for having your real interactive agent do it, rather than a detached background process.
- Report-only. If you want it to apply fixes automatically it is one edit away, but think hard before letting anything self-edit the files that steer every session unattended. The safer pattern is report-on-a-loop, apply-on-review.
- To disable, remove the SessionStart entry (or open `/hooks`).
