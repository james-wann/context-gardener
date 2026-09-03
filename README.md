# context-gardener

A Claude Code skill that treats your AI's context documents as code: it audits them for drift, reports what it finds ranked by how badly each issue could mislead a future session, and repairs them safely by staging every change on a duplicate for your review before anything live is touched. It is built to run read-only on a recurring loop, so your context stays accurate without you remembering to check.

## Why this exists

`CLAUDE.md`, `AGENTS.md`, a profile doc, a memory index: these load into an assistant's context and silently steer every session. Like code, they drift. Someone edits one rule and not its twin elsewhere. A repo gets renamed and forty pointers rot. A memory's filename keeps encoding a decision that was reversed months ago. The assistant then acts on stale or self-contradictory instructions and nobody notices, because nobody re-reads their own config.

The leverage in working with AI has moved from wording prompts to engineering the context the model works from. This skill maintains that context as a first-class job.

## Two versions, pick your surface

- **Claude Code / local** (`skills/context-gardener`) audits a local file surface: `~/.claude/CLAUDE.md`, project `CLAUDE.md`, an `@`-include tree, a `MEMORY.md` index. Install with the plugin commands below.
- **Cowork / hosted** (`context-gardener-cowork/`) is for Cowork and other hosted Claude surfaces, where the steering context is a persistent memory store, account skills and connected folders rather than local files. Add it through your hosted app's skill settings. See [`context-gardener-cowork/README.md`](context-gardener-cowork/README.md).

Install the one that matches where you work. They share the same seven checks and the same stage-before-you-touch-live safety model.

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
- What it does at **every** tier is the durable value: it stages every change on a duplicate and shows the diff before anything live moves, it preserves the history a rename would otherwise flatten, and it gives you a repeatable, loopable procedure and a shared vocabulary for the checks.

It does not claim a universal win. The `SKILL.md` says the same.

## Modes

- **report**, detect and report only, never writes or stages. Safe for an unattended or scheduled run.
- **review** (default), detect, report, then stage every fix on a duplicate and show you the diffs. Nothing live is touched until you explicitly say apply.
- **auto**, the same staging model on a loop where you are present each iteration. It reports the diffs loudly but still never touches a live file without your go.

## Install

**Option A, drop it in (works everywhere).** Copy the skill folder into your Claude Code skills directory:

```
cp -r skills/context-gardener ~/.claude/skills/
```

On Windows, copy `skills\context-gardener` into `C:\Users\<you>\.claude\skills\`. Start a new session and it is available.

**Option B, as a plugin.**

```
/plugin marketplace add https://github.com/james-wann/context-gardener.git
/plugin install context-gardener@james-wann
```

**Keeping it updated.** The plugin tracks this repo, so pushed changes reach you automatically. To force a refresh:

```
/plugin marketplace update james-wann
```

On other tools (Codex, Cursor, Gemini CLI), re-pull the skill folder or use that tool's own update mechanism.

## Run it

Just ask, in a session where the skill is installed:

> Audit my context docs and tell me what's drifted or contradictory.

It reports, then stages any fixes on a duplicate and shows you the diffs. Nothing live changes until you say apply.

## The recursive part: run it on a loop

The point is not to remember to run it. Wire it to a Claude Code **SessionStart hook** so it audits your context on a cadence (7 days by default), read-only, and hands you a report. See [`loop/README.md`](loop/README.md) for the script and the one settings entry. Windows and macOS/Linux versions are in [`loop/`](loop/).

## Safety

Your live context files are never edited in place. Every change is staged on a duplicate and shown to you as a diff first; nothing is promoted to live without your explicit instruction, in any mode. Promotion never blind-renames (every reference is updated in the same pass), watches for the bulk-rename flatten trap, snapshots live first so it is reversible, and re-verifies that nothing dangles afterwards. The scheduled loop is report-only.

## Licence

MIT. Built by James Wann.
