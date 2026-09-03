# context-gardener-cowork

Context hygiene for Cowork and the other hosted Claude surfaces, where the things that steer a session are a persistent memory store, a set of account skills and whatever folder happens to be connected, rather than a `.claude` directory you can open.

Sibling to [context-gardener](https://github.com/james-wann/context-gardener), which covers the local Claude Code file surface. Same seven checks, same safety model, different surface and different mechanics.

## Why a separate skill

`context-gardener` assumes a filesystem: `~/.claude/CLAUDE.md`, project and subdirectory `CLAUDE.md`, an `@`-include tree, a `MEMORY.md` index. It discovers by listing directories, stages by copying them, and promotes by moving files.

A hosted session has none of that. The container is fresh every time, so there is no user-level `CLAUDE.md` and nothing persists in one. What persists is reached through tools:

- the **memory store** that follows the user across surfaces: profile, preferences, topics, areas, people
- the **account skills**, whose one-line descriptions sit in context on every single turn and decide what fires
- the **installed plugins** and the skills they carry, sharing that same trigger space
- any **connected folder** on the user's machine, which is where `CLAUDE.md` and `AGENTS.md` come back into scope

Three things change as a result, and they are why this is a separate skill rather than a section in the original: discovery enumerates tools instead of directories, staging cannot be a `cp -r` and an account skill cannot be written to as a file at all, and there is a privacy rail with no local equivalent, because the memory store has categories it must not hold and a tidy-up is exactly where one gets reintroduced.

## The finding it exists to catch

An account skill's `description` is in context on **every turn of every session**, whether or not the skill ever fires. Its body loads only when it triggers.

So a description that has drifted from its body costs on every run, and it costs in the worst way: the wrong skill fires, or the right one does not, and the user experiences that as Claude being unreliable rather than as a stale document. Two skills claiming overlapping trigger phrases do the same thing.

Those two findings lead the report in this environment, ahead of anything in the memory store. A contradiction in a topic file is read occasionally. A description collision is read constantly.

## The seven checks

Shared with the sibling skill deliberately, so the vocabulary transfers. Where each one points in a hosted session is in [`references/checks.md`](skills/context-gardener-cowork/references/checks.md).

1. **Internal contradictions**, one document arguing both sides of the same rule.
2. **Cross-document contradictions**, resolved by precedence. Includes trigger collisions between skills, and a skill body silently overriding a stored preference.
3. **Stale claims vs ground truth**, checked against reality and never asserted wrong without a check. This is the check that degrades in a hosted session, and the skill says unverified rather than padding it.
4. **Label vs content drift**, most expensively a skill description against its own body.
5. **Broken references and fragmentation**, dead wikilinks and dead URLs, plus two skills that are really one skill under two product names.
6. **Broken content promise**, a reference that resolves but whose target does not contain what the pointer promised. A skill citing a canonical URL is the archetype.
7. **Stale by omission**, a document that covers the harmless case and stays silent on the dangerous one.

## Safety model

Unchanged in intent, adapted in mechanism. Nothing live moves until you have seen the exact diff and said go, in every mode.

- Memory files are read out into the session workspace as a pristine copy and a staged copy. The workspace is outside the loaded surface by construction, which is the one thing easier here than on a local surface.
- Version tokens are respected. A conflict means another surface wrote while the audit was staging: merge and keep their change, never force past it.
- The narrowest write wins. A whole-file memory write replaces the entire file and deletes every line left out, which is the hosted equivalent of the bulk-rename flatten trap.
- A skill change goes through the platform's own review card, which you save or discard. Skill files visible on disk are a read-only cache; editing them changes nothing, and reporting such an edit as a fix is a false claim.
- Deletion is one-way and cross-surface, so it only happens when you explicitly ask for something to be forgotten. Never as tidying.
- Blocked categories stay out of the store and out of the report. Consolidation must not enrich a stated fact into an inferred one.

Full detail in [`references/staging.md`](skills/context-gardener-cowork/references/staging.md).

## Modes

- **report**, detect and report only, never writes or stages. The mode for an unattended scheduled run.
- **review** (default), detect, report, stage, show the diffs. Nothing live is touched until you say apply.
- **auto**, the same staging model on a `/loop` where you are present each iteration. It reports the diffs loudly and still never writes live without your go.

## Install

**As an account skill (works in Cowork, claude.ai and Claude Code).** Ask Claude in a Cowork session to add this as a skill and point it at this repository, or paste [`SKILL.md`](skills/context-gardener-cowork/SKILL.md) and ask for it as a skill proposal. You will get a review card; saving it installs the skill on your account. Account skills are a single file, so the four reference files get folded into the body as appendices.

**As a plugin (Claude Code, keeps the reference files separate).**

```
/plugin marketplace add james-wann/context-gardener-cowork
/plugin install context-gardener-cowork@james-wann
```

**Dropped in (Claude Code).**

```
cp -r skills/context-gardener-cowork ~/.claude/skills/
```

## Run it

> Audit my memory and skills and tell me what's drifted or contradictory.

It reports, then stages any fixes and shows you the diffs. Nothing live changes until you say apply.

## On a schedule

The original wires itself to a Claude Code `SessionStart` hook. Hosted sessions have no such hook, so the equivalent is a scheduled task that fires a fresh session in `report` mode. See [`schedule/README.md`](schedule/README.md) for the prompt and the cadence.

## Honest positioning

Inherited from the sibling skill, and it still holds. On the weaker, cheaper models most people run day to day, this catches drift an unaided model misses and holds it back from confident wrong fixes. On a top-tier model the detection edge shrinks, because a strong model audits this well unaided.

What holds at every tier is the procedure: it stages outside the loaded surface and shows the diff before anything live moves, it respects the version tokens rather than clobbering a concurrent write from another surface, it keeps blocked categories out of both the store and the report, and it gives a repeatable, schedulable vocabulary for the checks.

The hosted surface adds one claim the original cannot make: a local audit has no equivalent of the skill trigger space, so the description-drift and collision findings are new rather than adapted.

## Licence

MIT. See [LICENSE](LICENSE).
