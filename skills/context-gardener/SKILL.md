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
  reports findings ranked by how likely each is to mislead, and on request stages fixes on a
  reviewable duplicate, applying them to the live files only on instruction. Use this whenever the user
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

The reason to be careful rather than clever: these files shape the assistant's behaviour on every future run. A wrong "fix" is worse than the drift, because it looks authoritative. So the whole skill is built around verifying against reality, staging every change on a duplicate the user reviews before anything live is touched, and never breaking a reference while repairing another.

## What this adds, and where

Be honest about the value, because it changes with the model running the skill (this is measured against fixtures, not asserted).

On a weaker model, the kind most teams run day to day, this skill measurably catches drift the model misses unaided: a reference that resolves but does not deliver the content it promised, a glossary that disambiguates the harmless name clash and stays silent on the dangerous one. It also holds the model back from the confident wrong "fix", the speculative flag or the edit to a real external thing that only shares a name. Those are the structural checks (3, 4, 6, 7) that a weaker model does not run on its own.

On a top-tier model the detection edge disappears, because it already audits this well unaided. There the value narrows to what the skill does at every tier: it stages every change on a duplicate and shows the diff before anything live moves (a capable model will otherwise rename correctly and still edit live with no undo), it preserves the history a rename would otherwise flatten, and it gives a repeatable, loopable procedure and a shared vocabulary for the checks. Claim the detection win only for weaker models. Do not overstate it on a strong one.

## When to use it

Reach for this when someone wants their context docs reconciled, audited, pruned, or checked against reality, or when they are about to share/hand off those docs and need them trustworthy. It also runs well on a cadence (see Modes) to catch drift early.

It is not a general file editor. It works specifically on the documents that configure an assistant, and its value comes from knowing what drift looks like in those documents and how to repair it without collateral damage.

## Modes

Pick the mode from how the run is invoked. When unclear, default to **review**.

- **report** — detect and report only. Never writes, never stages. This is the mode for a headless, unattended run (a cron job, a scheduled routine): nobody is watching, so it must not touch anything. It is also the right mode when the user just wants an audit.
- **review** — the default. Detect, report, then stage every approved fix on a duplicate of the context surface and show the user the diffs. Nothing live is touched. The reviewed changes are promoted to the live files only on an explicit instruction ("apply", "go"). This is the deliberate one-off clean-up: the user sees exactly what would change before any live file moves.
- **auto** — for `/loop` and similar, where a human IS present each iteration. Same staging model as review: detect, stage on the duplicate, and report the diffs loudly. It still never promotes to live without an explicit go that iteration; the only difference from review is that it re-runs on the loop. `auto` does not mean automatic application. The "nothing goes live without an instruction" rule holds in every mode.

Detection and staging are side-effect-free as far as the live files are concerned: staging writes only to the duplicate. That is what lets these modes run on a loop or schedule safely: the one risky step (promoting the duplicate to live) is a separate phase, gated behind an explicit instruction, that you can skip entirely.

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

### 5. Stage every change on a duplicate

Never edit a live context file in place. After the report exists, duplicate the context surface — every file a fix would touch — into a clearly-named location OUTSIDE the loaded surface. Do not stage inside `~/.claude/` or any project directory the assistant reads, or the staged copies become new context and new drift; use a scratch/temp area or a sibling `*-staging/` directory. Mirror the relative paths so references still resolve. Apply all approved fixes to the duplicate, not to the originals. Follow the safety rails below without exception; they are the difference between gardening and vandalism.

### 6. Show the diffs and wait

Show the user a per-file diff of duplicate vs live, ranked the same way as the report. Then STOP. Nothing live has changed, and nothing changes until the user explicitly says to apply. This review gate is not optional: a wrong "fix" to context is worse than the drift it replaces, so the user must see the exact change before it lands. In `report` mode you never reach this step; in `review`/`auto` you wait here for the go.

### 7. Promote to live (only on instruction)

Only when the user explicitly approves, promote the reviewed changes from the duplicate onto the live files. Snapshot the pre-promotion live state first so the promotion itself is reversible. Honour the never-blind-rename rail: a rename is the write of the new file plus a repoint of every reference plus removal of the old, all of which were already staged and reviewed.

### 8. Verify (converge)

After promoting, re-run the reference-integrity and contradiction checks against the live files. Confirm zero dangling references and that you introduced no new contradiction. If a fix created a new problem (renames are the usual culprit), repair it (again via the duplicate) and re-scan. This is a bounded loop, expect one or two passes, not an open-ended one.

## Safety rails

These are the point of the skill. They are also the teaching content if you are demonstrating it; explain the why, not just the rule.

- **Verify before asserting; cheapest check first.** "This path is wrong" needs an `ls`, not a hunch. The failure mode is confidently correcting something that was actually fine and breaking it.
- **Stage on a duplicate; never edit a live file in place. This is the rail a capable model skips.** Testing bears this out: an otherwise careful model will rename correctly, update references, and verify itself, and still edit live with no way back, because nothing forced it to work on a copy first. So duplicate the surface, make every change on the copy, show the diff, and promote to live only on an explicit instruction. State where the duplicate is. The pre-promotion live state is your backup; snapshot it before promoting so the promotion is reversible too.
- **Never blind-rename.** When you rename a file or a slug, you must update every reference to it in the same pass: index links, wikilinks, backlinks, path pointers, `@includes`. Then verify zero dangling references. A rename that leaves half its pointers behind is worse than the mismatch you were fixing.
- **Watch the bulk-rename flatten trap.** A find/replace across many files silently corrupts the lines whose whole purpose was to document the OLD name. See `references/pitfalls.md` for the worked example; the rule is: after any bulk rename, scan for lines that now say "X = X" or otherwise lost the old→new mapping they were recording. Historical and mapping references are exactly what a blind replace destroys.
- **Nothing goes live without an explicit instruction, in every mode.** The staging step is the safety net: the user always sees the exact diff before any live file moves, and can walk away with live untouched. `auto` does not weaken this — it stages and reports on a loop but still waits for the go each iteration. Never trade the review gate away for speed.

## Pruning and demotion (optional)

If the surface includes an always-loaded index (like a `MEMORY.md` that loads every session), it accumulates. Offer to prune, but do not impose it, and be honest: terse entries often carry a durable gotcha or a "where it lives" fact even when the task is "done", so the genuinely disposable set is usually small. Do not manufacture a big cull.

A light, safe demotion pattern (details and a reference script sketch in `references/pitfalls.md`): tag purely-shipped, no-longer-actionable entries with a date, and move them out of the always-loaded index into a not-loaded reference file once they age past a threshold, unless they are marked to keep. Make demotion opt-in per entry so it can never surprise-remove something durable.

## Output and tone

Recommendation-first. Rank by impact. Plain labels, not manufactured headings; state the fact and stop. UK English. When you finish, say plainly what you staged, what (if anything) you promoted to live, what you deliberately did not, where the duplicate and any snapshot are, and anything you could not verify.
