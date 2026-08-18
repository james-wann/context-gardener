# The seven detection checks, in depth

Run all seven. For each finding, capture: what, where (full path + line), why it misleads, and a concrete fix. Rank the final report by potential to mislead, not by ease of fix.

## 1. Internal contradictions

One document that says two incompatible things about the same rule or fact. These are the most dangerous drift, because a reader resolves the conflict silently and you cannot predict which side they land on, so behaviour becomes a coin toss.

How to find them: they usually appear when a document was edited in one place to reflect a new decision but an older section restating the same rule was missed. Look for a considered "new position" section and then a stale restatement elsewhere (a summary list, a calibration section, an examples block). Duplication is the breeding ground; if a rule is stated in three places, check all three agree.

Fix: make the newest, most considered statement the single source, and align or delete the stale restatements. If the document repeats the same rule many times, that repetition is itself worth flagging, because it is where the next contradiction will hide.

## 2. Cross-document contradictions

Two documents that disagree. Resolve with the precedence order established during discovery: the higher-precedence document is treated as correct, and the lower one is flagged for correction. If precedence is undefined, that missing rule is a finding in its own right.

A special case: two peer documents that are supposed to say the same thing (e.g. a CLAUDE.md and a profile doc that both list the same rules). When they drift, you have two sources of truth for one rule. Recommend consolidating to one and having the other reference it, rather than maintaining both.

Another easily-missed subtype: **procedural/mechanism contradictions**, where the same action is described two incompatible ways across (or within) documents. "Deploy by running `./scripts/deploy.sh`" in one place and "pushing to `main` triggers the deploy via CI" in another are not obviously in conflict, they read as two facts, so they survive a quick scan. But they describe one action with two mechanisms, and following the wrong one causes a double-deploy or an out-of-band change. Actively look for the same verb (deploy, release, publish, migrate) described differently in two places.

## 3. Stale claims vs ground truth

The highest-value check and the one most skills skip. A context doc is full of factual claims: file paths, repo and org names, version numbers, counts, dates, who owns what. Any of these can silently go stale.

Verify against reality, cheapest check first:
- **Paths**: `ls` / test existence. A pointer to a moved or renamed file is a common, quiet failure.
- **Repos / orgs**: `git remote -v`, `gh repo view`. Renames and org migrations leave stale `old-org/repo` references that still 301 today but will break later.
- **Versions / counts / dates**: check against the authoritative source the doc itself names (a status file, a manifest, the live system). If the doc says "v2.3, redeploy pending" and the status file says "v2.6 live", the doc is two versions behind.

Discipline: never assert a claim is wrong without a check. If you cannot verify it (no access, no ground truth), label it **unverified** and move on. Fabricating a correction is far worse than leaving a claim flagged.

## 4. Slug/filename vs content, and title/description drift

The label and the body disagree. Two forms:
- **Filename/slug encodes a retired position.** A memory saved as `..._not_migrated.md` whose content now says "migrated on 2026-05-01". Any reader who trusts the slug (or greps filenames) before reading the body gets the exact opposite of the truth. Fix by renaming the file/slug to match the content, then updating every reference (see the never-blind-rename rail).
- **Index line or description no longer matches the body.** A one-line summary in an index, or a frontmatter `description`, that describes an older version of the fact. Fix the summary to match the current body.

## 5. Broken references and fragmentation

Two opposite problems, both about how entries relate.

**Broken references**: dead wikilinks (`[[name]]` with no matching file), dangling markdown links, `@includes` pointing at moved files, path pointers to renamed directories. Grep for the link forms and confirm each target exists. Renames elsewhere are the usual cause, which is why the verify step after applying is not optional.

**Fragmentation**: the opposite. Several entries that are really one fact, or a cluster that only makes sense read together (e.g. three separate notes about one repo's confusing git layout). These bloat an always-loaded index and hide contradictions between themselves. Recommend consolidating a genuine cluster into one entry.

But resist over-merging. If a system holds "one fact per file", merging genuinely distinct facts into a mega-entry violates its design and recalls worse, not better. Consolidate only what is truly one fact fragmented; leave distinct facts distinct, and say so when you decline to merge something the user expected merged.

## 6. Broken content promise

A reference that resolves but lies about what is on the other side. The link, wikilink or `@include` points at a file that genuinely exists, so the reference-integrity half of check 5 passes it as healthy. But the reason the reference was made, the content it promises, is not actually in the target. A reader follows a good link to the wrong place and trusts what they find (or fails to find).

This is the check that hides behind a clean check 5. Check 5 asks "does the target exist?"; this asks "does the target contain what the pointer said it would?". A link passes the first and fails the second, and a skill that only greps link targets will call it healthy.

How to find them: read the sentence around each reference, not just the link itself. It usually carries a promise, "the schema for X is in [[Y]]", "see Z for the retention policy", "config lives in `foo/bar`". Open the target and confirm the promised thing is actually there. The tell is a specific noun in the promise (a token schema, a retention figure, an owner) that never appears in the target.

Fix: correct the pointer to the file that really holds the content, add the missing content to the target, or reword the promise to match what the target actually says. Do not leave it just because the link resolves.

Worked example (hard fixture): `paylink_auth.md` says "Schema for the stored token record is in [[paylink_data_model]]", and that file exists, so check 5 is satisfied. But `paylink_data_model.md` only describes transaction storage and retention; it never mentions a token record. The link is live and the promise is false.

## 7. Stale by omission

A document addresses one case and, by doing so, implies it has the area covered, while staying silent on a more dangerous adjacent case. Nothing written is wrong, so the contradiction checks (1 and 2) find nothing. The damage is the gap: a reader takes the doc's handling of the harmless case as reassurance that the dangerous one is handled too.

How to find them: watch for disambiguation, warnings and "not to be confused with" notes, then ask what the worse version of that same confusion would be and whether the doc mentions it. A glossary that warns about one name collision is a prompt to check whether a nastier collision exists elsewhere in the surface and went unlisted. This check depends on having mapped the whole surface (step 2); the omission is only visible once you can see the case the doc failed to mention.

Fix: add the missing case to the doc that already owns the topic, so its coverage matches the real risk. Report it as a gap, not a contradiction, so it is not mistaken for one of the earlier checks.

Worked example (hard fixture): `glossary.md` warns not to confuse the PSP category with the own-service `paylink`, a low-stakes clarification. It says nothing about the genuinely dangerous collision introduced in `vendor_integrations.md`: a third-party vendor literally named **Paylink** (paylink.co.uk), an external provider whose API is unrelated to the own-service `paylink`. The glossary disambiguates the harmless pair and omits the harmful one.
