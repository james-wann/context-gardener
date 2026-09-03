# Worked pitfalls and patterns

Real failure modes seen while doing this work by hand. Each is a trap the skill exists to avoid, and each is good material if you are demonstrating the skill. The examples below are illustrative.

## The bulk-rename flatten trap

The single nastiest failure. You rename something (a repo, a folder, a product name) and sweep the new name across all the docs with a find/replace. It works everywhere except the lines whose whole job was to record the OLD name.

Worked example. A project's local folder used to be called `oldshop`; the GitHub repo is `webshop`. A doc carried a deliberate mapping line to reduce confusion:

```
oldshop = webshop = shop.example.com   (folder = repo = domain)
```

A blind `oldshop` → `webshop` replace turns that into:

```
webshop = webshop = shop.example.com
```

which is now nonsense; the mapping it was documenting is destroyed. The same replace also flattens any line elsewhere that contrasted the current name against the retired one ("worked from the `webshop` clone; `oldshop` is a stale checkout"), leaving both halves identical.

The rule: **after any bulk rename, scan for the damage.** Grep for `X = X` patterns, for the same token repeated adjacently where a contrast used to be, and re-read any line that was specifically about naming, history, or old to new migration. Historical and mapping references are precisely the content a blind replace corrupts, because their value was in holding the old string. Prefer targeted, context-aware edits over a global replace on anything that documents naming.

## Slug outlives the decision

A memory or file saved under a name that encodes a decision, when the decision later reverses. Example: `storefront_repo_not_migrated.md` whose content was updated to "migrated on 2026-05-01; the old note is retired". The body is right; the filename lies, and anyone who reads the slug first (or greps filenames) is misled on the current state. Fix by renaming the file and its `name:`/slug to match the content, then repointing every reference (index link, wikilinks, in-doc mentions) and verifying none dangle.

## Duplicate clones and fragmented clusters

Two local clones of the same repo on different branches read as "two repos" until you check the remotes (`git remote -v` on each) and find they share an origin. The confusion is a documentation problem: notes accumulate that describe the muddle from different angles. Consolidate the genuinely-one-topic notes (e.g. "the canonical clone is here", "main lives in a worktree there", "a stray clone keeps reappearing") into a single "git layout" entry, but keep a distinct fact (e.g. "this repo's CI does not publish a production status") separate. Merging distinct facts to look tidy makes recall worse.

## Pruning: the disposable set is smaller than it looks

When asked to prune an always-loaded index, the instinct is a big cull. In practice, terse entries usually carry a durable gotcha or a "where it lives" fact even when the task itself is finished. "240 records imported 2026-01-10" also tells a future reader where they live and that a manifest lists them; "flaky test quarantined" also carries "re-enable it after the fix". Those earn their place.

The test for each line: does it record a **durable gotcha or location** (keep) or merely that a **task finished** (candidate to demote)? Report the honest result even when it is "almost nothing is disposable"; do not manufacture a cull to look busy.

## Demotion pattern (opt-in, ages out)

A safe way to keep an always-loaded index lean without losing history:

- Tag a purely-shipped, no-longer-actionable line with a date marker, e.g. `(shipped: 2026-07-10)`.
- A maintenance pass moves any such line older than a threshold (say 30 days) out of the always-loaded index into a not-loaded reference file, unless the line also carries a `(keep)` marker.
- Untagged lines are never touched. This makes demotion **opt-in per line**, so it can never surprise-remove a durable entry.
- The underlying fact/file stays on disk and still surfaces on demand; only its always-loaded index pointer moves.

Sketch of the sweep (adapt to your tooling and paths; keep it dry-run by default and back up the index before writing):

```
for each line in INDEX:
    if line matches "(shipped: YYYY-MM-DD)" and not "(keep)":
        if date < today - N days:
            move line from INDEX to REFERENCE   # never touch the underlying file
back up INDEX before writing; report what moved; require an explicit apply flag
```

Do not wire an unattended, auto-applying version into a per-session hook: an index that rewrites itself every session can churn or compound an error. A manual or scheduled dry-run-then-apply is safer.

---

# Hosted-surface pitfalls

## The whole-file write truncation

The hosted equivalent of the bulk-rename flatten trap, and just as nasty. A whole-file memory write replaces the entire file: every line not included is deleted. There is no partial write and no merge.

It bites during consolidation, which is exactly when it is most tempting. You read a file, rewrite it tidier, and the two terse lines that read as noise do not make it into the new version. Those are usually the ones carrying a durable gotcha or a "where it lives" fact, because that is what terse lines look like.

The rule: use a targeted replacement for anything short of a deliberate restructure, and when restructuring, carry every line forward on purpose and diff the result against the pristine copy before writing. If the staged file has fewer facts than the live one, that is a decision, not a side effect, and it belongs in the diff the user approves.

The same hazard applies to a skill definition, which also replaces wholesale. Read the current definition in full, carry everything forward, change only what the finding named.

## Editing the read-only cache

A hosted session may show skill directories in its own filesystem. They look editable. They are a cache: writing to them changes nothing about the live skill, and the change vanishes with the container.

The failure is not the wasted edit, it is the report. "Fixed the description in `skills/foo/SKILL.md`" is a false claim of a kind this skill exists to catch elsewhere. A skill change is only real once the user has saved the corrected definition. Proposed and installed are different states.

## The rename that erases its own map

Renaming a memory file and repointing every reference is correct and still incomplete if you drop the old name. The old name is what makes future mentions match: someone says the retired product name and nothing resolves.

Add the old name to the file's `aliases`. The rail is the same one as the flatten trap: the value of a historical string is that it holds the old name, so erasing it destroys the mapping the rename needed.

## Forcing past a version conflict

A memory write rejected on version grounds means another surface wrote while you were staging. The rejection hands you the current content.

The wrong move is to re-read and write your staged version over the top, which silently destroys their change and looks like success. Merge their change into yours and retry in the same turn. A conflict is routine and is not a reason to stop and ask permission.

## Reporting a thin check 3 as a clean one

With no folder connected, most path and repo claims cannot be verified. The temptation is to report the check as passed, because nothing came back wrong.

Nothing came back at all. Say unverified, name what would make it verifiable (connecting the folder that holds the repos), and keep the honest short list. A clean bill of health from an audit that could not look is the most misleading output this skill can produce.

## Tidying that quietly adds a claim

Consolidation invites a summarising sentence, and a summarising sentence invites an inference. Two adjacent stated facts merged into one line often come out saying something neither of them said.

Merge only what is truly one fact fragmented, keep the merged line at the level the user actually stated, and if you cannot merge without inferring, leave the lines separate and say why. This matters more here than on a local surface, because the store is subject to content rules and because it follows the user everywhere.

## Deleting to tidy

Deletion is one-way and removes the file from every surface the user works from. It happens only when they explicitly ask for that subject to be forgotten. Never to deduplicate, never because a file looks stale, never as part of a pruning pass they approved in general terms. Removing a single fact is a targeted replacement, not a file deletion.
