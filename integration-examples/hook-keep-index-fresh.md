# Example — PostToolUse hooks to keep summary indexes fresh

The summary helpers (`gdd-summary.sh`, `adr-summary.sh`, `registry-summary.sh`) all rely on per-item summary files at a `_summaries/` subdirectory. If you edit a source file but don't regenerate the summary, the summary drifts silently and downstream skills act on stale data.

The fix: PostToolUse hooks that re-run the relevant `--rebuild` command whenever a source file is edited.

---

## Example 1 — `validate-gdd-write.sh`

Triggers on Edit/Write to any `design/gdd/*.md` file. Rebuilds the matching summary.

```bash
#!/bin/bash
# .claude/hooks/validate-gdd-write.sh
# PostToolUse hook — fires after any Edit/Write that touches design/gdd/<slug>.md.
# Re-runs the summary build so the _summaries/ index stays fresh.

set -e

# The harness passes the modified file path as $CLAUDE_TOOL_FILE_PATH
# (exact env var name varies by deployment — adapt if your hook surface differs).
file="${CLAUDE_TOOL_FILE_PATH:-$1}"

# Only act on GDD source files (not the summaries themselves).
if [[ ! "$file" =~ ^design/gdd/[a-z][a-z0-9-]*\.md$ ]]; then
  exit 0
fi
if [[ "$file" =~ /_summaries/ ]]; then
  exit 0
fi

# Extract the slug from the filename: design/gdd/combat.md → combat
slug="$(basename "$file" .md)"

# Rebuild the summary. The script is idempotent and fast (~200ms typical).
bash tools/dev/gdd-summary.sh "$slug" --rebuild > /dev/null

# Optional: surface a one-line confirmation to the conversation so the user
# knows the summary was refreshed (helpful when debugging staleness).
echo "GDD summary refreshed: design/gdd/_summaries/$slug.md"
```

**Register in `settings.json`:**

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit", "command": ".claude/hooks/validate-gdd-write.sh" },
      { "matcher": "Write", "command": ".claude/hooks/validate-gdd-write.sh" }
    ]
  }
}
```

(Exact JSON shape varies by Claude Code version — refer to your `.claude/settings.json` schema.)

---

## Example 2 — `validate-adr-write.sh`

Same shape, for ADRs at `docs/architecture/adr-NNNN-*.md`.

```bash
#!/bin/bash
# .claude/hooks/validate-adr-write.sh

set -e
file="${CLAUDE_TOOL_FILE_PATH:-$1}"

if [[ ! "$file" =~ ^docs/architecture/adr-[0-9]{4}-.*\.md$ ]]; then
  exit 0
fi
if [[ "$file" =~ /_summaries/ ]]; then
  exit 0
fi

# Extract the 4-digit ADR number: docs/architecture/adr-0023-some-slug.md → 0023
adr_num="$(basename "$file" | sed -E 's/^adr-([0-9]{4})-.*$/\1/')"

bash tools/dev/adr-summary.sh "$adr_num" --rebuild > /dev/null
echo "ADR summary refreshed: docs/architecture/_summaries/adr-$adr_num.md"
```

---

## Example 3 — `validate-active-md.sh`

This hook validates the Session Extract schema rather than rebuilding a summary. Warns on PostToolUse when a writer used a non-conforming top-level H2.

```bash
#!/bin/bash
# .claude/hooks/validate-active-md.sh

set -e
file="${CLAUDE_TOOL_FILE_PATH:-$1}"

if [[ "$file" != "production/session-state/active.md" ]]; then
  exit 0
fi

# Scan for any top-level H2 that is NOT a Session Extract.
# The STATUS block at the top (an HTML comment) is fine; anything else is drift.
non_conforming=$(awk '
  /^## / && !/^## Session Extract/ {
    print "WARN: non-conforming H2 at line " NR ": " $0
  }
' "$file")

if [[ -n "$non_conforming" ]]; then
  echo "active.md schema validator: drift detected"
  echo "$non_conforming"
  echo "(Schema: every top-level H2 below STATUS must be \"## Session Extract — DATE — TITLE\")"
fi

# Optional: check that the newest extract has a TL;DR first line per the
# active-md-template.md §Hard Rule 6.
first_extract=$(awk '/^## Session Extract/ { print NR; exit }' "$file")
if [[ -n "$first_extract" ]]; then
  tldr_line=$(awk -v start="$first_extract" 'NR > start && /^- \*\*TL;DR:\*\*/ { print NR; exit }' "$file")
  if [[ -z "$tldr_line" ]] || [[ $((tldr_line - first_extract)) -gt 4 ]]; then
    echo "WARN: newest Session Extract is missing the TL;DR first line."
  fi
fi
```

This is warn-only (doesn't block the write); promotes to error after the project has dogfooded the schema for a sprint or two.

---

## Example 4 — `validate-registry-write.sh`

Lighter touch — re-runs the registry self-check rather than rebuilding the summary (the registry summary is computed on demand, not cached).

```bash
#!/bin/bash
# .claude/hooks/validate-registry-write.sh

set -e
file="${CLAUDE_TOOL_FILE_PATH:-$1}"

if [[ "$file" != "design/registry/entities.yaml" ]]; then
  exit 0
fi

# Verify the registry is still valid YAML with the expected schema.
# Exit non-zero if it's broken (which blocks the tool call surface in some
# hook configurations — desirable for a registry write).
python3 -c "
import yaml, sys
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    assert isinstance(data, list), 'top-level must be a list of entities'
    for entity in data:
        assert 'id' in entity, 'entity missing id field'
        assert 'source' in entity, 'entity ' + str(entity.get('id', '?')) + ' missing source field'
    print(f'Registry validated: {len(data)} entities.')
except Exception as e:
    print(f'Registry validation FAILED: {e}', file=sys.stderr)
    sys.exit(1)
"

# Re-run the summary to refresh top-N counts.
bash tools/dev/registry-summary.sh > /dev/null
```

---

## Pattern: PreToolUse vs PostToolUse

- **PostToolUse** is the common case. The edit succeeds; the hook re-runs the index build. If the hook fails, the warning surfaces but the file is already saved.
- **PreToolUse** is for blocking writes that would corrupt downstream state (e.g., breaking the registry YAML). Use sparingly; PreToolUse failures abort the tool call entirely.

For summary-freshness hooks, PostToolUse is correct — you don't want to block a GDD edit just because the summary rebuild had a transient issue.

---

## Adoption sequence

1. Adopt the summary helpers first (Phase 5 of the integration guide).
2. Once you have ≥1 stale summary (caught by `<helper> --check`), adopt the matching hook.
3. Run the hook in warn-only mode for one sprint before promoting to error.
4. Add `--check` to your `/gate-check` or session-start hook so stale summaries surface even if the PostToolUse hook misfired.

---

## Common pitfalls

- **Hook failures masquerading as edit failures.** If the hook crashes (Python missing, script not executable, etc.), some hook surfaces report the error as if the file write failed. Always test the hook with a successful invocation before relying on it.
- **Recursive hook firing.** If your hook rebuilds the summary, and the rebuild writes to `_summaries/<file>`, AND that path matches the PostToolUse trigger, you get infinite recursion. Add a guard for `_summaries/` paths at the top of the hook (Example 1 does this).
- **Hook timing across multiple edits.** If a skill edits 5 GDDs in sequence, the hook fires 5 times. That's usually fine (~1s per fire), but if rebuild cost grows, consider batching at session-stop instead.
