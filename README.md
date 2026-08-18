# context-gardener

A Claude Code skill that treats your AI's context documents as code: it audits them for drift, reports what it finds ranked by how badly each issue could mislead a future session, and repairs them safely with backups. It is built to run read-only on a recurring loop, so your context stays accurate without you remembering to check.

## Why this exists

`CLAUDE.md`, `AGENTS.md`, a profile doc, a memory index: these load into an assistant's context and silently steer every session. Like code, they drift. Someone edits one rule and not its twin elsewhere. A repo gets renamed and forty pointers rot. A memory's filename keeps encoding a decision that was reversed months ago. The assistant then acts on stale or self-contradictory instructions and nobody notices, because nobody re-reads their own config.

The leverage in working with AI has moved from wording prompts to engineering the context the model works from. This skill maintains that context as a first-class job.

## What it checks

Seven checks, run in order, each ranked by how badly it could mislead:

1. **Internal contradictions**, one document arguing both sides of the same rule.
2. **Cross-document contradictions**, two documents that disagree, resolved by precedence (including the same action described two incompatible ways).
3. **Stale claims vs ground truth**, paths, repo/org names, versions, counts and dates checked against reality, never asserted wrong without a check.
4. **Slug/filename vs content**, a file whose name encodes a position the body has since reversed.
5. **Broken references and fragmentation**, dead links and includes, plus clusters that should be consolidated.
6. **Broken content promise**, a link that resolves but whose target does not contain what the pointer promised.
7. **Stale by omission**, a doc that handles a harmless case and stays silent on a more dangerous adjacent one.

## Honest positioning

This was measured with an A/B evaluation across model tiers, not asserted. The honest result:

- On the weaker, cheaper models most people run day to day, it catches drift an unaided model misses and holds the model back from confident wrong "fixes".
- On a top-tier model the detection edge shrinks, because a strong model already audits this well unaided.
- What it does at **every** tier is the durable value: it backs up and previews before writing, it preserves the history a rename would otherwise flatten, and it gives you a repeatable, loopable procedure and a shared vocabulary for the checks.

It does not claim a universal win. The `SKILL.md` says the same.

## Modes

- **report**, detect and report only, never writes. Safe for an unattended or scheduled run.
- **review**, detect, report, then apply the fixes you approve. The default for a hands-on run.
- **auto**, detect, report loudly, then apply in one pass, for a loop where you are present each iteration. Report-first and backups are non-negotiable here.

## Install

**Option A, drop it in (works everywhere).** Copy the skill folder into your Claude Code skills directory:

```
cp -r skills/context-gardener ~/.claude/skills/
```

On Windows, copy `skills\context-gardener` into `C:\Users\<you>\.claude\skills\`. Start a new session and it is available.

**Option B, as a plugin.**

```
/plugin marketplace add james-wann/context-gardener
/plugin install context-gardener@james-wann
```

## Run it

Just ask, in a session where the skill is installed:

> Audit my context docs and tell me what's drifted or contradictory. Don't change anything yet.

That runs the report. To let it apply fixes, say so; it backs up first and shows you the change.

## The recursive part: run it on a loop

The point is not to remember to run it. Wire it to a Claude Code **SessionStart hook** so it audits your context on a cadence (7 days by default), read-only, and hands you a report. See [`loop/README.md`](loop/README.md) for the script and the one settings entry. Windows and macOS/Linux versions are in [`loop/`](loop/).

## Safety

Detection never writes. Applying always backs up first, never blind-renames (every reference is updated in the same pass), watches for the bulk-rename flatten trap, and re-verifies that nothing dangles afterwards. The scheduled loop is report-only and never applies changes on its own.

## Licence

MIT. Built by James Wann.
