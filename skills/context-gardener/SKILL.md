---
name: context-gardener
description: >-
  Audit, reconcile, consolidate and prune the context documents an AI assistant loads to
  understand a user and their projects: CLAUDE.md at every scope, AGENTS.md / GEMINI.md,
  @-referenced includes, the .claude memory index (MEMORY.md) and its memory files, and any
  profile or TODO docs the user treats as canonical. Finds internal and cross-document
  contradictions, claims that have gone stale against the real filesystem/git, filename-vs-content
  mismatches, broken cross-references and fragmentation, references that resolve but do not contain
  what they promised, and dangerous gaps left when a doc disambiguates only the harmless case;
  reports findings ranked by how likely each is to mislead, and on request applies fixes safely with
  backups. Use this whenever the user
  asks to audit, review, clean up, reconcile, consolidate, prune, tidy or "garden" their context,
  config, memory or instruction files; says their CLAUDE.md / memory / AGENTS.md is drifting, going
  stale, or contradicting itself; asks "is my context still accurate" or "what's out of date in my
  setup"; wants context checked against reality before sharing or handing it off; or wants recurring
  context hygiene (e.g. via /loop or a scheduled routine). Trigger even when the user does not say
  the word "context" but is clearly asking to reconcile or sanity-check the documents that steer the
  assistant.
---

# Context Gardener

## The mental model

Context documents are code. CLAUDE.md, memory files, AGENTS.md, a profile doc, a canonical TODO: these load into an assistant's context and silently steer every session. Like code, they drift. Someone edits one rule and not its twin elsewhere. A repo gets renamed and forty pointers rot. A memory's filename keeps encoding a decision that was reversed months ago. The assistant then acts on stale or self-contradictory instructions and nobody notices, because nobody re-reads their own config.

This skill treats that drift as a bug class and runs a review-and-fix loop over it: discover the context surface, detect drift, report it ranked by how much damage it can do, and (on request) repair it safely.

The reason to be careful rather than clever: these files shape the assistant's behaviour on every future run. A wrong "fix" is worse than the drift, because it looks authoritative. So the whole skill is built around verifying against reality, previewing before writing, and never breaking a reference while repairing another.

## What this adds, and where

Be honest about the value, because it changes with the model running the skill (this is measured against fixtures, not asserted).

On a weaker model, the kind most teams run day to day, this skill measurably catches drift the model misses unaided: a reference that resolves but does not deliver the content it promised, a glossary that disambiguates the harmless name clash and stays silent on the dangerous one. It also holds the model back from the confident wrong "fix", the speculative flag or the edit to a real external thing that only shares a name. Those are the structural checks (3, 4, 6, 7) that a weaker model does not run on its own.

On a top-tier model the detection edge disappears, because it already audits this well unaided. There the value narrows to what the skill does at every tier: it backs up and previews before writing (a capable model will otherwise rename correctly and still edit live with no undo), it preserves the history a rename would otherwise flatten, and it gives a repeatable, loopable procedure and a shared vocabulary for the checks. Claim the detection win only for weaker models. Do not overstate it on a strong one.

## When to use it

Reach for this when someone wants their context docs reconciled, audited, pruned, or checked against reality, or when they are about to share/hand off those docs and need them trustworthy. It also runs well on a cadence (see Modes) to catch drift early.

It is not a general file editor. It works specifically on the documents that configure an assistant, and its value comes from knowing what drift looks like in those documents and how to repair it without collateral damage.

## Modes

Pick the mode from how the run is invoked. When unclear, default to **review**.

- **report** — detect and report only. Never writes. This is the mode for a headless, unattended run (a cron job, a scheduled routine): nobody is watching, so it must not touch config. It is also the right mode when the user just wants an audit.
- **review** — detect, report, then apply the fixes the user approves. The default for a deliberate one-off run where the user asked for a clean-up and is present to say go.
- **auto** — detect, report loudly, then apply in the same pass. This is for `/loop` and similar, where a human IS present each iteration, so the loud report is the review and application can follow immediately. Two things are non-negotiable in this mode: emit the full findings report BEFORE making any change, so the user can interrupt if something looks wrong, and back up every file you touch. The safety net when apply follows report automatically is entirely: report-first + backups + reversibility.

Detection is deliberately a clean, side-effect-free step. That is what lets `report`/`auto` be dropped into a loop or schedule safely: the expensive, risky part (writing) is a separate phase you can gate or skip.

## Workflow

Work through these in order. Announce which mode you are in at the start.

### 1. Discover the context surface

Find every document that actually loads or is treated as canonical. Do not assume; go and look. See `references/discovery.md` for the full enumeration across platforms and scopes. In short:

- `CLAUDE.md` at every scope that applies: the user/global one (`~/.claude/CLAUDE.md`), the project root, and any subdirectory ones.
- Files pulled in by `@path` includes from those (a profile doc, a house-style doc).
- `AGENTS.md` / `GEMINI.md` if present (other assistants' equivalents).
- The memory system if present: the `MEMORY.md` index plus the individual memory files it points at.
- Any doc the user names as canonical (a TODO source-of-truth, a decisions log).
- Anything the user explicitly points the skill at.

List what you found and, crucially, the **precedence order** between them, because half of drift detection depends on knowing which document wins when two disagree. If the docs state their own precedence (e.g. "most recent instruction > CLAUDE.md > profile > memory"), use that. If they don't, ask or infer the obvious order and state your assumption.

### 2. Map claims and references

Read the surface and build a working picture of: the behavioural rules, the factual claims (paths, repo/org names, versions, counts, dates, ownership), and the cross-references (wikilinks, markdown links, `@includes`, path pointers). You are looking for what can rot, so note anything checkable against the real world.

### 3. Detect (the seven checks)

Run all seven. Detail and heuristics for each are in `references/checks.md`; the summary:

1. **Internal contradictions.** One document that argues both sides of the same rule. These are the most damaging because a reader resolves them silently, and which way they resolve is a coin toss.
2. **Cross-document contradictions.** Two documents that disagree. Resolve using the precedence order from step 1, and flag the loser for correction. Include **procedural/mechanism contradictions**, the same action described two incompatible ways (e.g. "run the deploy script manually" vs "push to main triggers it via CI"). These read as complementary rather than conflicting, so they slip past a quick scan, but acting on the wrong one causes real harm (a double-deploy, an out-of-band change).
3. **Stale claims vs ground truth.** Check factual claims against reality: do referenced paths exist (`ls`), are repo/org names current (`git remote`, `gh`), are versions/counts/dates still true? Cheapest check first. Never assert a claim is wrong without checking; if you genuinely cannot verify it, say "unverified", do not guess.
4. **Slug/filename vs content, and title/description drift.** A file whose name encodes a position the content has since reversed (a `..._not_migrated.md` that now says "migrated on 2026-05-01"), or an index line/description that no longer matches the body. These quietly mislead any reader who trusts the label before the text.
5. **Broken references and fragmentation.** Dead wikilinks, dangling `@includes`, path pointers to moved/renamed files; and the opposite problem, several entries that are really one fact, or a cluster that only makes sense read together and should be consolidated.
6. **Broken content promise.** A reference that resolves but whose target does not contain what the pointer promised (a link to a file "for the token schema" whose target never mentions tokens). It passes a plain reference-integrity check, so it hides behind a clean check 5; read the promise in the sentence, then confirm the target actually delivers it.
7. **Stale by omission.** A document that handles a harmless case and stays silent on a more dangerous adjacent one (a glossary that disambiguates a low-stakes name clash but misses a genuinely confusable third-party vendor of the same name). Nothing written is wrong, so the contradiction checks miss it; the finding is the gap, visible only once the whole surface is mapped.

### 4. Report

Produce a findings report ranked by how likely each issue is to mislead a future session, not by how easy it is to fix. Lead with the one that would most change behaviour. For each finding: what it is, where (full paths), why it misleads, and a concrete recommendation. Be honest about confidence: mark anything you could not verify. If a check came back clean, say so in a line rather than padding.

In `report` mode you stop here. In `review`/`auto` you continue.

### 5. Apply (safely)

Only after the report exists (and, in `review`, after the user picks what to apply). Follow the safety rails below without exception; they are the difference between gardening and vandalism.

### 6. Verify (converge)

After applying, re-run the reference-integrity and contradiction checks. Confirm zero dangling references and that you introduced no new contradiction. If a fix created a new problem (renames are the usual culprit), repair it and re-scan. This is a bounded loop, expect one or two passes, not an open-ended one.

## Safety rails

These are the point of the skill. They are also the teaching content if you are demonstrating it; explain the why, not just the rule.

- **Verify before asserting; cheapest check first.** "This path is wrong" needs an `ls`, not a hunch. The failure mode is confidently correcting something that was actually fine and breaking it.
- **Back up before any write; this is the rail a capable model skips.** Testing bears this out: an otherwise careful model will rename correctly, update references, and verify itself, and still edit live with no way back, because nothing forced it to snapshot first. So copy the file (or the whole surface) somewhere recoverable BEFORE the first edit, every time, and state where the backup is and how to undo. It is the difference between a reversible mistake and a permanent one. Preview the change before applying it, too.
- **Never blind-rename.** When you rename a file or a slug, you must update every reference to it in the same pass: index links, wikilinks, backlinks, path pointers, `@includes`. Then verify zero dangling references. A rename that leaves half its pointers behind is worse than the mismatch you were fixing.
- **Watch the bulk-rename flatten trap.** A find/replace across many files silently corrupts the lines whose whole purpose was to document the OLD name. See `references/pitfalls.md` for the worked example; the rule is: after any bulk rename, scan for lines that now say "X = X" or otherwise lost the old→new mapping they were recording. Historical and mapping references are exactly what a blind replace destroys.
- **Reversibility is the safety net, especially in `auto`.** When application follows the report automatically, the only thing standing between a bad fix and lasting damage is that you reported first (so a human could interrupt) and backed up (so it can be undone). Never trade either away for speed.

## Pruning and demotion (optional)

If the surface includes an always-loaded index (like a `MEMORY.md` that loads every session), it accumulates. Offer to prune, but do not impose it, and be honest: terse entries often carry a durable gotcha or a "where it lives" fact even when the task is "done", so the genuinely disposable set is usually small. Do not manufacture a big cull.

A light, safe demotion pattern (details and a reference script sketch in `references/pitfalls.md`): tag purely-shipped, no-longer-actionable entries with a date, and move them out of the always-loaded index into a not-loaded reference file once they age past a threshold, unless they are marked to keep. Make demotion opt-in per entry so it can never surprise-remove something durable.

## Output and tone

Recommendation-first. Rank by impact. Plain labels, not manufactured headings; state the fact and stop. UK English. When you finish, say plainly what you changed, what you deliberately did not, where the backups are, and anything you could not verify.
