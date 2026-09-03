---
name: context-gardener-cowork
description: >-
  Audit, reconcile, consolidate and prune the context that steers a hosted Claude session in Cowork
  or claude.ai: the persistent memory store (profile, preferences, topics, areas, people), the
  account skills whose descriptions decide what triggers and whose bodies decide what happens, the
  installed plugins, and any CLAUDE.md / AGENTS.md / GEMINI.md inside a connected folder. Finds
  internal and cross-document contradictions, skill trigger collisions, description-vs-body drift,
  claims that have gone stale against the real filesystem or git, broken references, references that
  resolve but do not contain what they promised, and dangerous gaps left where a document covers only
  the harmless case; reports findings ranked by how likely each is to mislead, stages every fix
  outside the loaded surface, and writes to the live memory store or a skill definition only on
  instruction. Use this whenever the user asks to audit, review, clean up, reconcile, consolidate,
  prune, tidy or "garden" their memory, preferences, skills, plugins or instruction files; says their
  memory or skills are drifting, going stale, contradicting each other or triggering wrongly; asks
  "is what Claude knows about me still accurate", "why did the wrong skill fire" or "what's out of
  date in my setup"; wants their setup checked before handing it to a colleague; or wants recurring
  context hygiene on a schedule. Trigger even when the user does not say the word "context" but is
  clearly asking to reconcile or sanity-check the things that steer the assistant. For a local
  Claude Code file surface (a ~/.claude directory, project CLAUDE.md, an @-include tree), use the
  sibling skill context-gardener instead.
---

# Context Gardener (Cowork)

## The mental model

Context is code. In a hosted session it just does not live in files you can open. What steers Claude here is a persistent memory store reached through tools, a set of account skills whose one-line descriptions sit in context on every single turn, a handful of installed plugins, and whatever repository documents happen to be in a connected folder. All of it drifts exactly like code drifts. A preference gets refined in conversation and the stored version keeps the old wording. A product gets renamed and two skills keep the retired name in their trigger phrases. A memory file records a decision that was reversed a quarter ago. Claude then acts on stale or self-contradictory instructions and nobody notices, because nobody re-reads their own setup.

This skill treats that drift as a bug class and runs a review-and-fix loop over it: discover the surface, detect drift, report it ranked by how much damage it can do, and on request repair it safely.

The reason to be careful rather than clever: this surface shapes behaviour on every future session, across every device the user works from. A wrong "fix" is worse than the drift, because it looks authoritative and it is now the stored truth. So the skill is built around verifying against reality, staging every change outside the loaded surface, and never writing to live memory or a skill definition without an explicit instruction.

## How this differs from context-gardener

The sibling skill, `context-gardener`, audits a local Claude Code surface: `~/.claude/CLAUDE.md`, project and subdirectory `CLAUDE.md`, an `@`-include tree, a `MEMORY.md` index. It assumes a filesystem it can list, diff and copy.

A hosted session has none of that. The container is fresh each time, so there is no user-level `CLAUDE.md` to audit and nothing persists in it between sessions. The persistent surface is reached through tools instead of paths, which changes three things:

- **Discovery** enumerates tools, not directories. See `references/surfaces.md`.
- **Staging** cannot be a `cp -r`. Memory files have to be read out into the session workspace, and an account skill cannot be edited as a file at all. See `references/staging.md`.
- **There is a privacy rail.** The memory store has categories that must never be filed, and a report that quotes stored personal detail back at the user is its own harm. The local surface has no equivalent. See `references/staging.md`.

The seven checks are shared with the sibling skill deliberately, so the vocabulary transfers. What is new here is where they point and what the highest-leverage finding is.

## The highest-leverage finding in a hosted session

Say this plainly when reporting, because it is not obvious and it is where the value concentrates.

An account skill's `description` is in context on **every turn of every session**, whether or not the skill ever fires. Its body loads only when it triggers. So a description that has drifted from its body costs on every run, and it costs in the worst way: it makes the wrong skill fire, or stops the right one firing, and the user experiences that as Claude being unreliable rather than as a stale document.

That makes description-vs-body drift (check 4) and trigger collision between two skills (check 2) the two findings to lead with in this environment, ahead of anything in the memory store. A contradiction buried in a topic memory file is read occasionally. A description collision is read constantly.

## What this adds, and where

Be honest about the value, because it changes with the model running the skill.

On a weaker model this catches drift the model misses unaided: a reference that resolves but does not deliver the content it promised, a glossary that disambiguates the harmless name clash and stays silent on the dangerous one, two skills whose trigger phrases overlap. It also holds the model back from the confident wrong fix and from editing a real external thing that only shares a name.

On a top-tier model the detection edge shrinks, because a strong model audits this well unaided. What holds at every tier: it stages outside the loaded surface and shows the diff before anything live moves, it respects the version tokens rather than clobbering a concurrent write from another surface, it keeps blocked categories out of both the store and the report, and it gives a repeatable, schedulable procedure and a shared vocabulary for the checks. Claim the detection win only for weaker models.

## Modes

Pick the mode from how the run is invoked. When unclear, default to **review**.

- **report** — detect and report only. Never writes, never stages. This is the mode for an unattended run, which in a hosted session means a scheduled task: nobody is watching, so it must not touch anything. It is also the right mode when the user just wants an audit.
- **review** — the default. Detect, report, then stage every approved fix outside the loaded surface and show the user the diffs. Nothing live is touched. Reviewed changes are written to the live memory store only on an explicit instruction ("apply", "go"). Skill changes go through the platform's own review card, which the user saves or discards.
- **auto** — for `/loop` and similar, where a human is present each iteration. Same staging model as review: detect, stage, report the diffs loudly. It still never writes live without an explicit go that iteration. `auto` does not mean automatic application. The "nothing goes live without an instruction" rule holds in every mode.

Detection and staging leave the live surface untouched, which is what lets these modes run on a loop or a schedule safely. The one risky step, writing to live, is a separate phase gated behind an explicit instruction, and it can be skipped entirely.

## Workflow

Work through these in order. Announce which mode you are in at the start.

### 1. Discover the surface

Do not assume; go and look. `references/surfaces.md` carries the full enumeration and the tool for each. In short:

- **The memory store.** `memory_list` first, then read what looks relevant: `/profile.md`, `/preferences.md`, `/topics/*`, `/areas/*`, `/people/*`. The listing shows paths, not content.
- **Account skills.** The enabled set, each one's description and, where it matters, its body. Skill files that appear on disk are a read-only cache, not the live definition.
- **Installed plugins** and the skills they carry, which can collide with account skills.
- **Connected folders**, if any. `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` and any doc the user names as canonical inside them. With no folder connected, say so, because it bounds what check 3 can verify.
- **Anything the user points the skill at.**

List what you found before reading deeply, so the user can correct the surface ("you missed the plugin skills"). Then state the **precedence order**, because half of drift detection depends on knowing which document wins. This surface almost never states its own precedence, so you will usually be inferring it: say which order you are using so it can be corrected before you act on it. `references/surfaces.md` gives the conventional order and the reasoning.

### 2. Map claims and references

Build a working picture of: the behavioural rules (mostly `/preferences.md` and skill bodies), the factual claims (paths, repo and org names, product names, URLs, versions, counts, dates, ownership), and the cross-references (wikilinks between memory files, markdown links, URLs a skill cites as canonical, paths into a connected folder). You are looking for what can rot, so note anything checkable against the real world.

Also map the **trigger space**: which phrases each skill claims. Overlaps are findings.

### 3. Detect (the seven checks)

Run all seven. Depth and heuristics are in `references/checks.md`, which also carries the hosted-surface cases for each. The summary:

1. **Internal contradictions.** One document arguing both sides of the same rule. The most damaging, because a reader resolves them silently and which way is a coin toss. In this environment `/preferences.md` and a long skill body are where these breed.
2. **Cross-document contradictions.** Two documents that disagree, resolved by the precedence order from step 1. Includes procedural contradictions, the same action described two incompatible ways, and the hosted-surface case that matters most: **two skills claiming the same triggers**, which is a contradiction the user experiences as the wrong skill firing.
3. **Stale claims vs ground truth.** Check factual claims against reality: do referenced paths exist, are repo and org names current, are the cited URLs live, are versions, counts and dates still true? Cheapest check first. In a hosted session much of this is only verifiable when a folder is connected or a URL can be fetched. Never assert a claim is wrong without checking. If you cannot verify it, say **unverified**; do not guess. Expect this check to return thinner here than it does on a local surface, and say so rather than padding it.
4. **Label vs content drift.** A skill `description` that no longer matches its body, a memory file whose frontmatter `description` describes an older version of the fact, a filename or slug that encodes a position the content has since reversed. In this environment the skill description is the high-cost form; see the section above.
5. **Broken references and fragmentation.** Dead wikilinks between memory files, links to files that moved in a connected folder, dead URLs; and the opposite problem, several entries that are really one fact, or two skills that are really one skill under two product names.
6. **Broken content promise.** A reference that resolves but whose target does not contain what the pointer promised. It passes a plain reference-integrity check, so it hides behind a clean check 5. Read the promise in the sentence, then confirm the target delivers it. A skill citing a canonical URL is the common hosted case: fetch it and check it still says what the skill claims.
7. **Stale by omission.** A document that handles a harmless case and stays silent on a more dangerous adjacent one. Nothing written is wrong, so the contradiction checks miss it. The finding is the gap, visible only once the whole surface is mapped.

### 4. Report

Rank by how likely each issue is to mislead a future session, not by how easy it is to fix. Lead with anything that changes which skill fires, then anything in `/preferences.md`, then the rest. For each finding: what it is, where (the exact memory path or skill name), why it misleads, and a concrete recommendation. Mark anything unverified. If a check came back clean, say so in a line rather than padding.

Keep the privacy rail in view while writing the report: do not quote stored personal detail back at the user beyond what the finding actually needs, and do not surface a sensitive stored fact the user has not raised in this conversation. `references/staging.md` has the rule.

In `report` mode you stop here. In `review` and `auto` you continue.

### 5. Stage outside the loaded surface

Never edit live in place. The mechanics differ by surface and are set out in full in `references/staging.md`. The shape:

- **Memory files.** Read each file that a fix would touch and write two copies into the session workspace: a pristine `live/` copy and a `staged/` copy you edit. Keep the version token from each read. The session workspace is outside the loaded surface by construction, which is the one thing that is easier here than on a local surface.
- **Account skills.** These cannot be edited as files. A change means producing the complete corrected definition and putting it to the user through the platform's own review card, which is itself the review gate. Stage the corrected text in the workspace first so it can be diffed against the current one.
- **Connected-folder documents.** Stage into the session workspace, not into a sibling directory inside the folder, or the staged copies become new context and new drift.

Apply all approved fixes to the staged copies only. Follow the safety rails below without exception.

### 6. Show the diffs and wait

Show a per-file diff of staged against live, ranked the same way as the report. Then stop. Nothing live has changed and nothing changes until the user explicitly says to apply. This gate is not optional: a wrong fix to stored context is worse than the drift it replaces, because it becomes the stored truth on every surface the user works from.

### 7. Write to live (only on instruction)

Only on explicit approval. For memory, write with the version token from the read that produced the staged copy, and prefer the narrowest operation that does the job: a targeted replace over a whole-file write, because a whole-file write deletes every line you left out. A version conflict means another surface wrote while you were staging: merge and retry in the same turn, keeping their change. Never force past it. Deletion happens only when the user explicitly asked for that thing to be forgotten.

For skills, put the complete corrected definition to the user and let them save it. Do not describe a saved skill as installed until it is.

### 8. Verify (converge)

Re-run the reference-integrity and contradiction checks against the live surface. Confirm nothing dangles and that you introduced no new contradiction, including no new trigger collision, which is the usual way a description fix backfires. If a fix created a problem, repair it through staging again and re-scan. Bounded loop: expect one or two passes.

## Safety rails

These are the point of the skill. Explain the why, not just the rule.

- **Verify before asserting; cheapest check first.** "This path is wrong" needs a check, not a hunch. The failure mode is confidently correcting something that was fine.
- **Stage outside the loaded surface; never write live in place.** A capable model will diagnose correctly and still write straight to live memory with no way back, because nothing forced it to work on a copy first. Read out, copy, edit the copy, diff, then write on instruction. State where the staged copies are.
- **Respect the version tokens.** Every memory read returns one and every write requires it. A conflict is not an obstacle to route around; it means another session or surface changed the file. Merge and keep their change. Forcing past a conflict silently destroys someone else's write.
- **Prefer the narrowest write.** A whole-file memory write replaces the entire file, so any line omitted is deleted. This is the hosted-surface equivalent of the bulk-rename flatten trap: it looks like an edit and behaves like a truncation. Use a targeted replace unless you are deliberately restructuring, and when you are, carry every line forward on purpose.
- **Never blind-rename.** Renaming a memory file or a skill means updating every reference in the same pass: wikilinks, index lines, aliases, cross-skill mentions. Then verify nothing dangles. Add the old name to the file's aliases rather than erasing it, so future mentions still match.
- **Keep blocked categories out of the store and out of the report.** Consolidating memory is not a licence to re-file something the store is not allowed to hold, and a tidy-up must not enrich a stated fact into an inferred one. Report a gap without quoting the sensitive content. `references/staging.md` carries the rule and the list.
- **Nothing goes live without an explicit instruction, in every mode.** The staging step is the safety net: the user always sees the diff first and can walk away with live untouched. `auto` does not weaken this. Never trade the review gate for speed.

## Pruning and demotion (optional)

The memory store accumulates, and unlike a local index it is read across every surface the user works from, so bloat there is not free. Offer to prune, but do not impose it, and be honest: terse lines often carry a durable gotcha or a "where it lives" fact even when the task is finished, so the genuinely disposable set is usually small. Do not manufacture a cull.

Two hosted-surface specifics. Files are size-capped, so the right move on a long file is usually to condense related lines rather than to delete facts. And deletion is one-way and cross-surface: a file removed here is gone from claude.ai chat too, so it happens only on an explicit ask for that thing to be forgotten, never as tidying. `references/pitfalls.md` has the demotion pattern and the traps.

## Output and tone

Recommendation-first. Rank by impact. Plain labels, not manufactured headings; state the fact and stop. UK English. When you finish, say plainly what you staged, what if anything was written to live, what you deliberately did not touch, where the staged copies are, and anything you could not verify.
