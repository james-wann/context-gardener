# context-gardener recurring gate (Windows / PowerShell).
# Wire this to a Claude Code SessionStart hook. It fires at most once per
# $intervalDays: when due it stamps the run time and injects an instruction
# telling the interactive agent to run context-gardener in REPORT mode over the
# ~/.claude context surface. Silent (exit 0, no output) otherwise.
# Report-only by design; it never applies changes.

$ErrorActionPreference = 'SilentlyContinue'
$intervalDays = 7
$claude       = Join-Path $env:USERPROFILE '.claude'
$stateFile    = Join-Path $claude 'state\context-gardener-last-run.txt'
$reportsDir   = Join-Path $claude 'context-gardener-reports'

# Due check: due if no stamp, an unparseable stamp, or a stamp >= interval old.
$due = $true
if (Test-Path $stateFile) {
    $raw  = (Get-Content $stateFile -Raw)
    $last = [datetime]::MinValue
    if ($raw -and [datetime]::TryParse($raw.Trim(), [ref]$last)) {
        if ((New-TimeSpan -Start $last -End (Get-Date)).TotalDays -lt $intervalDays) { $due = $false }
    }
}
if (-not $due) { exit 0 }

# Stamp now, so the hook never fires more often than once per interval even if
# this session ends before the sweep runs.
New-Item -ItemType Directory -Force -Path (Split-Path $stateFile) | Out-Null
New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
$now = Get-Date
Set-Content -Path $stateFile -Value $now.ToString('o') -NoNewline

$reportPath = Join-Path $reportsDir ($now.ToString('yyyy-MM-dd') + '.md')

$msg = @"
SCHEDULED CONTEXT HYGIENE ($intervalDays-day cadence): it has been at least $intervalDays days since the last context-gardener sweep of the ~/.claude context surface.

Run the context-gardener skill now in REPORT mode only (read-only; do not edit, rename, delete, or apply anything). Discover and audit the context surface: the global CLAUDE.md, any @-included profile or house-style docs, AGENTS.md / GEMINI.md if present, and the memory index and its files if present. Produce the ranked findings report and write it to: $reportPath

Then tell the user in one line that the scheduled context-gardener sweep ran, where the report is, and that they can review it and ask you to apply fixes (nothing has been changed). If the user is clearly mid-task, run the sweep after their immediate request rather than interrupting it. Do not apply any changes in this run.
"@

[pscustomobject]@{
    hookSpecificOutput = [pscustomobject]@{
        hookEventName     = 'SessionStart'
        additionalContext = $msg
    }
} | ConvertTo-Json -Depth 5 -Compress

exit 0
