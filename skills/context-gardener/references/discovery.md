# Discovering the context surface

The goal is to find every document that actually steers the assistant, plus the order in which they win when they disagree. Missing one means auditing a partial picture; getting precedence wrong means "fixing" the document that was actually correct.

## Where to look (Claude Code native)

- **User / global CLAUDE.md**: `~/.claude/CLAUDE.md` (on Windows, `C:\Users\<name>\.claude\CLAUDE.md`). Applies to every session in every project.
- **Project CLAUDE.md**: the repo/working-directory root. Adds to (does not replace) the global one.
- **Subdirectory CLAUDE.md**: some setups scope rules to a subtree. Check for `CLAUDE.md` below the root.
- **`@`-referenced includes**: grep the CLAUDE.md files for lines like `@./PROFILE.md` or `@path/to/file`. These pull other docs in verbatim; resolve each relative to the file that references it, and follow them (a profile doc, a house-style doc). A common false alarm: the `@ref` resolves to a different absolute path than the reader assumes; confirm the real target with `ls`.
- **Memory system** (if present): `~/.claude/projects/<slug>/memory/MEMORY.md` is an always-loaded one-line index; the individual `*.md` files beside it are recalled on demand. Treat MEMORY.md as an index to audit and the memory files as the facts.
- **Canonical working docs the user names**: a source-of-truth TODO, a decisions log. These are not auto-loaded config but the user treats them as authoritative, so drift in them matters.

## Other assistants

- **`AGENTS.md`** (used by several coding assistants) and **`GEMINI.md`** are the equivalents of CLAUDE.md. Same audit applies. If a project has more than one, they can drift against each other, which is itself a cross-document contradiction worth flagging.

## Establishing precedence

Detection of cross-document contradictions is meaningless without knowing which document wins. Determine precedence in this order:

1. **If the docs state it, use it.** A well-kept CLAUDE.md often says something like "most recent explicit instruction wins, then this file, then the profile, then memory." That is authoritative; use it verbatim.
2. **If they don't, infer and state your assumption.** The conventional order is: an explicit in-session instruction > project CLAUDE.md > user/global CLAUDE.md > referenced profile > memory. Say which order you are using so the user can correct it before you act on it.
3. **Flag the absence.** If precedence is undefined and two docs genuinely conflict, that missing rule is itself a finding: recommend the user add a precedence line, because without one the assistant resolves conflicts unpredictably.

## Practical enumeration

- List the files first, with full absolute paths, before reading deeply. The user should be able to see the surface you are about to audit and correct it ("you missed the one in `packages/api/`").
- Note which are always-loaded vs on-demand vs canonical-but-not-loaded. Always-loaded docs earn the most scrutiny because their drift costs on every run.
- Do not read entire large memory directories blindly; read the index, then targeted files. Grep for cross-references rather than opening everything.
