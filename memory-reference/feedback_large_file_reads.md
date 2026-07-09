---
name: Large file reads — cap initial Read at ~200 lines
description: Read tool fails opaquely past ~25k tokens on the Claude Code web client. For known-large files, pass limit ≤200 on first Read and expand with offset/limit only if the head doesn't answer the question.
type: feedback
---

On first Read of any file likely to exceed 25k tokens, pass
`limit: 150–300`. Expand with offset/limit only if the head doesn't
answer the question. For cross-file needs, prefer Grep over reading
whole files.

**Why:** the Claude Code web client does not surface the "File content
exceeds maximum allowed tokens" error cleanly — it shows only a generic
"command failed." Terminal surfaces the error correctly, but the user
works in both. Failing silently to a 25k-token cap is a UX trap that
wastes a turn.

**Known offender shapes in CCGS projects:**

- Top-level taxonomy / index documents — often 2000+ lines.
- Per-domain catalog documents (mob/enemy bestiary, item catalog, status-
  effect catalog) — typically 1000-2000 lines.
- Per-region or per-area lore documents — 800-2000 lines each.
- NPC / faction databases — 1000+ lines when populated.
- `production/session-state/active.md` and any deferred-items register
  CCGS creates — these grow append-only and need rotation, not Read.

**How to apply:**

1. Before reading a file you haven't seen, check its size with `wc -l`
   or `ls -l` via Bash if you're uncertain — costs one tool call, saves
   a full-file token blowout.
2. For known-large files, default to `Read(file, limit: 200)` on first
   touch.
3. For "find X in this file" needs, use Grep with `-n` to locate the
   line, then `Read(file, offset: N, limit: 50)` for the surrounding
   context. The `partial-read-helper.sh` script in this bundle automates
   that pattern.
4. The harness "Edit must be preceded by Read" rule is satisfied by
   *any* prior Read — partial counts. A 5-line partial Read costs ~200
   tokens; a full Read of a 40k-token register costs 40k.
