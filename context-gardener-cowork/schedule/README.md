# Running it on a schedule

The point is not to remember to run it.

The sibling skill wires itself to a Claude Code `SessionStart` hook, which fires in a local session with a real `~/.claude` directory. A hosted session has no such hook and no local settings file, so the equivalent is a **scheduled task**: a cron-style schedule that starts a fresh session, runs the audit in `report` mode, and hands you the findings.

Two properties make this safe. The run is report-only, so it never stages and never writes. And every firing starts a fresh session with no memory of the last one, so a bad run cannot compound.

## Setting it up

Ask Claude, in a Cowork session:

> Set up a scheduled task that audits my context every Monday at 8am and reports what's drifted.

Claude creates it with the scheduled-task tools on the remote server. Two things to get right, and worth naming when you ask:

- **It must be a scheduled task, not a local cron.** A session-local scheduler dies with the session, and the task silently never fires again.
- **Schedules are evaluated in UTC.** For a local time that crosses midnight in conversion, the day fields shift too. Claude handles the conversion; this is here so you can sanity-check the result against what you asked for.

## The prompt to schedule

Every firing starts a fresh session, so the prompt has to be a complete standalone instruction. Adapt the scope line to your setup:

```
Run the context-gardener-cowork skill in report mode.

Audit my persistent memory store and my account skills for drift. Do not
stage anything and do not write to memory or propose a skill change: this is
an unattended run and report mode never writes.

Report only what has actually changed or gone wrong since it would have been
correct, ranked by how badly each finding could mislead a future session.
Lead with anything that affects which skill fires: a skill description that
has drifted from its body, or two skills claiming overlapping triggers. Then
anything in /preferences.md. Then the rest.

No folder is connected in a scheduled run, so most path and repo claims are
unverifiable. Label those unverified rather than clean, and keep the list
honest and short. If every check comes back clean, say so in two lines. Do
not pad.
```

## Cadence

Weekly is the sensible default. This surface drifts on the timescale at which you change your own setup, which for most people is weeks rather than days.

Worth firing an unscheduled run at three moments, because each one is a known drift event:

- after renaming a product, a client or a repository, which is what puts a retired name into a trigger list
- after adding or editing a skill, which is when a description and a body come apart
- before handing your setup to a colleague, which is the moment stale context stops being your problem and starts being theirs

## What not to automate

Do not schedule a run in `review` or `auto` mode, and do not schedule anything that applies fixes.

The whole safety model rests on a human seeing the diff before the store changes. An unattended run that writes has nobody to show it to, and a wrong fix to stored context is worse than the drift it replaced, because it becomes the stored truth on every surface you work from. The scheduled run's job is to tell you there is gardening to do. You do the gardening.
