# Discovering the surface in a hosted session

The goal is the same as on a local surface: find every document that actually steers the assistant, plus the order in which they win when they disagree. Missing one means auditing a partial picture; getting precedence wrong means "fixing" the document that was correct.

What differs is that most of this surface is reached through tools rather than paths, and that the session's own container holds nothing durable. Do not go looking for a user-level `CLAUDE.md` in a hosted session. There isn't one, and saying so is a finding of sorts: the user may believe there is.

## 1. The persistent memory store

The durable, cross-surface layer. It follows the user into claude.ai chat and every other surface, which is why drift here is the most widely felt.

- **Enumerate first.** The listing gives paths, sizes and last-updated times, not content. An empty or near-empty store is itself worth reporting.
- **Then read selectively.** Do not read the whole store blindly on a large account. Read `/preferences.md` and `/profile.md` always, because they govern behaviour and identity, then read what the listing suggests is relevant to the audit.
- **Conventional layout**, which is what you are auditing against:
  - `/profile.md` — who the user is, at the level that stays true for months. Anything dated or "currently" is misplaced here and belongs in `/areas/` or `/topics/`. Misplacement is a real finding: a "currently" fact in a profile is a stale claim waiting to happen.
  - `/preferences.md` — how the user wants the assistant to behave. This is the highest-consequence file in the store, because it governs every task rather than a topic.
  - `/topics/<domain>.md` — facts about the user by domain.
  - `/areas/<name>.md` — ongoing involvements: decisions, constraints, deadlines, status. The most drift-prone by nature, since status is what goes stale.
  - `/people/<name>.md` — relationship context, with `aliases` for other names the same person is called.
- **Frontmatter is auditable.** Each file should carry a `name` matching its path stem, a one-line `description` saying what it covers, `sources`, and for `/areas/` and `/people/` an `aliases` list. A `description` that no longer matches the body is check 4. A `name` that no longer matches the path is check 4 in its filename form.
- **Wikilinks** of the form `[[name]]` between files are check 5 territory. Confirm each target is a real path in the listing.
- **Every read returns a version token.** Keep it. Writes require it, and it is the mechanism that stops you clobbering a concurrent write from another surface.

## 2. Account skills

The layer that costs most per turn, and the one a local-surface audit has no equivalent for.

- **Enumerate the enabled set** and capture each skill's name and description. The description is the part that sits in context on every turn and decides triggering.
- **Read the bodies that matter.** A body loads only when the skill fires, so its drift costs less, but a body that contradicts its own description is what makes triggering unreliable.
- **Skill files on disk are a read-only cache.** In a hosted session you may find skill directories in the container filesystem. Editing them changes nothing about the live skill. Treat them as a convenient read, never as the thing to fix, and never report a file edit there as a fix applied.
- **What to look for specifically:**
  - **Trigger collisions.** Two skills whose descriptions claim overlapping phrases. The user experiences this as the wrong skill firing and rarely diagnoses it as a documentation problem.
  - **Retired product names in triggers.** A renamed product whose old name still sits in one skill's trigger list and not another's. Both halves are wrong in different directions: the old name over-triggers, the new name under-triggers.
  - **Two skills that are one skill.** The same subject under two product names or two eras. This is check 5 fragmentation at the skill level, and consolidating is a bigger change than it looks, so recommend rather than assume.
  - **Cited canonical sources.** A skill that names a URL or a document as canonical is making a promise. Check 6 applies: fetch it and confirm it still says what the skill claims.

## 3. Installed plugins

Plugins carry their own skills, which share the same trigger space as account skills and can collide with them. Enumerate what is installed and fold the plugin skills into the trigger map from step 2. A collision between a plugin skill and an account skill is the same finding as a collision between two account skills, and harder for the user to spot, because they think of plugins as separate.

## 4. Connected folders

A hosted session may be linked to the user's computer with one or more folders connected. If so, the local-surface documents come back into scope inside those folders:

- `CLAUDE.md` at the root of any repository there, and in subdirectories.
- `AGENTS.md` and `GEMINI.md`, the equivalents used by other assistants. Where a repo has more than one, they drift against each other, which is itself a cross-document contradiction worth flagging.
- `@`-referenced includes from those files, resolved relative to the file that references them.
- Any doc the user names as canonical: a source-of-truth TODO, a decisions log, a CONTEXT.md.

This is also the only place check 3 has real teeth, because it is the only filesystem and git you can actually interrogate. Use the shell on the connected folder for `ls` and `git remote -v` rather than staging files across just to look at them.

**When no folder is connected, say so explicitly in the report**, because it bounds the audit: most path and repo claims anywhere in the surface become unverifiable, and the honest label for them is unverified rather than clean.

## 5. Anything the user points at

An uploaded document, a repository, a doc they treat as the source of truth. Not auto-loaded, but authoritative in their head, so drift in it matters.

## Establishing precedence

Cross-document contradiction detection is meaningless without knowing which document wins. On a local surface the docs often state their own precedence. This surface almost never does, so you will usually be inferring it.

1. **If anything states it, use it.** A `/preferences.md` that says how conflicts resolve is authoritative; use it verbatim.
2. **Otherwise infer, and state the assumption.** The conventional order:
   1. The user's request in the current conversation. Always wins.
   2. The host application's own instructions, including a connector's standing instructions. Not editable and not your business to fix, but they set the frame and can be the real reason a stored rule appears to be ignored. Worth naming when it explains a finding.
   3. `/preferences.md`. Governs the whole session, every task.
   4. An invoked skill's instructions. Authoritative while the skill is running, silent otherwise. This is why a skill and a preference can coexist in contradiction for months without anyone noticing: they are rarely in context together.
   5. Topic, area and people memory files. Facts rather than rules, so they lose to anything above when they conflict on behaviour.
   6. Documents in a connected folder, which apply to work in that folder.
3. **Flag the absence.** If precedence is undefined and two documents genuinely conflict, that missing rule is a finding: recommend a precedence line in `/preferences.md`, because without one the resolution is unpredictable.

The item worth dwelling on is 4 against 3. A skill body that quietly contradicts a stored preference is the most common cross-document contradiction in this environment and the least visible, because the two only meet on the turns the skill happens to fire.

## Practical enumeration

- List the surface first, with exact memory paths and skill names, before reading deeply. The user should be able to see what you are about to audit and correct it.
- Note which parts are in context on every turn (skill descriptions, and `/preferences.md` in practice), which load on demand (skill bodies, most memory files), and which are canonical but not loaded at all. Always-in-context items earn the most scrutiny, because their drift costs on every run.
- Do not read the entire memory store or every skill body blindly. Enumerate, then read what the audit needs.
