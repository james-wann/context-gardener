# Staging and writing on a hosted surface

On a local surface, staging is a `cp -r` into a sibling directory and promotion is a file move. Neither works here. The memory store is not a filesystem, an account skill cannot be written to at all, and the one thing that is easier is that the session's own workspace is outside the loaded surface by construction, so there is no risk of the staged copies becoming new context.

The rail is unchanged: nothing live moves until the user has seen the exact diff and said go.

## Staging memory files

For every memory file a fix would touch:

1. **Read it, and keep the version token.** Every read returns one. It is required by every write and it is what stops you overwriting a change made from another surface while you were working.
2. **Write two copies into the session workspace.** A `live/` copy, untouched, and a `staged/` copy to edit. Mirror the memory paths under each so the diff reads cleanly and any wikilinks between files still resolve relative to each other. Example shape:

```
context-audit/
  live/     profile.md  preferences.md  areas/launch.md
  staged/   profile.md  preferences.md  areas/launch.md
  tokens.json
```

3. **Record the tokens alongside.** Keep the path-to-token mapping in the workspace, not in your head, because by the time the user approves you may be several turns from the read.
4. **Edit only the staged copy.** Never write to the store during staging, in any mode.
5. **Diff staged against live, per file**, ranked the way the report was ranked.

## Writing memory to live

Only on explicit approval.

- **Pass the version token from the read that produced the staged copy.** Not a fresh read taken after approval, unless you re-derive the staged content from it.
- **Prefer the narrowest operation.** A targeted string replacement over a whole-file write, and a whole-file write only when you are deliberately restructuring. A whole-file write replaces the entire file: every line you leave out is deleted. This is the hosted-surface equivalent of the bulk-rename flatten trap. It looks like an edit and behaves like a truncation, and the lines most likely to be lost are the terse ones carrying a durable gotcha, because they read as noise.
- **A targeted replacement must match exactly once.** Widen it with surrounding text until it is unique. Whitespace and newlines count. A failed match returns the current content, so fix the match from that rather than re-reading.
- **On a version conflict, merge and retry in the same turn.** A conflict means another session or another surface wrote while you were staging. The error carries the current content. Keep their change, re-apply yours on top, retry. Never force past it and never report the conflict as a failure of the audit; it is routine.
- **Update rather than overwrite the meaning.** "PM on infra team (previously search)" is a better fix than replacing the line, because it preserves the history that made the old line worth reading.
- **Fix the frontmatter description in the same write** if your edit made it wrong. Otherwise you have closed one check-4 finding by opening another.

## Renaming a memory file

The never-blind-rename rail, in its hosted form:

- Write the new path first, repoint every reference to it (wikilinks, index lines, mentions inside other files), then remove the old one. All of it staged and reviewed before any of it goes live.
- **Add the old name to the new file's `aliases`** rather than erasing it. Future mentions of the old name should still match one file. Erasing it is the flatten trap in another costume: you destroy the mapping that made the rename navigable.
- Verify nothing dangles afterwards.

## Deleting

Deletion is one-way and cross-surface. A file removed here is gone from every surface the user works from, including claude.ai chat.

So: **delete only when the user explicitly asks for that subject to be forgotten.** Never as tidying, never to deduplicate, never because a file looks stale. If it is unclear whether they mean one fact or the whole file, ask. Removing one fact is a targeted replacement to empty, not a file deletion.

## Staging an account skill

An account skill cannot be edited as a file. Skill directories visible in the container filesystem are a read-only cache: editing them changes nothing, and reporting such an edit as a fix applied is a false claim.

The route is to produce the **complete corrected definition** and put it to the user through the platform's own review card, which they save or discard. That card is the review gate, and it is stronger than the diff gate, because nothing can go live without the user's own action.

Two consequences worth building into the workflow:

- **A skill change replaces the whole definition.** There is no partial edit. So read the current definition in full, carry forward everything worth keeping, and change only what the finding called out. This is the whole-file write hazard again, with the same failure mode: quietly dropping a section nobody was looking at.
- **Stage the corrected text in the workspace first**, so you can diff it against the current definition and show the user what changed rather than handing them a wall of text and asking them to spot it. The card shows the result; the diff shows the decision.

Do not describe a skill as updated until the user has saved it. "Proposed" and "installed" are different states and conflating them is exactly the kind of false claim this skill exists to catch elsewhere.

## Staging a connected-folder document

Ordinary filesystem staging, with one rule: **stage into the session workspace, not into a sibling directory inside the connected folder.** A `*-staging/` directory inside a repository becomes new context for anything that reads that repository, so the fix introduces the drift it was meant to remove.

Otherwise the local-surface rails apply unchanged. Edit with a command that reads the file itself rather than retyping content from earlier tool output, which may have been truncated. Snapshot before promoting so the promotion is reversible. Verify nothing dangles afterwards.

## The privacy rail

This rail has no local-surface equivalent and it is not optional.

The memory store has categories it must not hold. Consolidating, condensing or rewriting memory is not a licence to reintroduce one, and a tidy-up is exactly where it happens, because merging two lines invites you to write a summarising sentence that says more than either line did.

Three rules:

1. **Do not re-file what the store is not allowed to hold.** If a line you are condensing carries a blocked category, the condensed version omits that part entirely. No neutral placeholder, no reworded shape. An omission gets no substitute.
2. **Do not enrich a stated fact into an inferred one.** Consolidation must not add a conclusion the user never stated: not a diagnosis, not a personality read, not an inference from two adjacent facts. A merged line stays at the level the user actually said. If you cannot merge two lines without inferring, do not merge them, and say why.
3. **Do not surface stored sensitive content in the report.** A finding can be reported without quoting it. "Two entries in `/people/` disagree on a date" is a finding; reproducing the surrounding personal detail is not necessary to it. Never raise a sensitive stored fact the user has not raised in this conversation. If a finding cannot be stated without it, describe the shape of the problem and its location and let the user open the file.

If a write is refused on content grounds, that refusal is final for those details and for nothing else. The refused write saved nothing at all, including its harmless parts, so re-save those in a fresh write without the refused details. Do not reword and retry the refused part, and do not report the harmless remainder as saved until a write has actually succeeded.

## Where the staged copies live, and saying so

The session workspace is ephemeral. It is the right place to stage, because it is outside the loaded surface and it disappears on its own, but it means the staged copies are not a backup and must not be described as one. If the user wants the pre-change state kept, the honest options are to send them the `live/` copies as files or to write them into a connected folder, and either way it is their call, not an assumption.

When you finish, say where the staged copies are, what was written to live, what was left alone, and what you could not verify.
