# Technical Debt Scan — Sprint 4 — 2026-07-10

## Summary

| Marker | Count | Location |
|--------|-------|----------|
| `ponytail:` | 3 | `tests/` only |
| `TODO` | 0 | — |
| `FIXME` | 0 | — |
| `HACK` | 0 | — |
| `XXX` | 0 | — |

**Verdict**: Clean. No debt markers in `src/`. All three `ponytail:` markers are intentional simplification annotations in test files with documented upgrade paths.

## Detailed Catalogue

### 1. `tests/integration/ui/l2_playable_loop_panels_test.gd:236`
```
# ponytail: Story 003 — accept authoritative or neutral; selected option may be empty when unavailable
```
- **Context**: Training summary assertions in L2 test relaxed from specific authoritative values to structural anchors.
- **Ceiling**: When training option auto-selection is fully restored via authoritative contract, these assertions can be tightened back to specific values.
- **Decision**: Keep. Valid simplification for Story 003 contract.

### 2. `tests/integration/ui/mvp_visual_walkthrough_runner.gd:37`
```
# ponytail: Story 003 — skip training confirm, go home, then jump to match flow
```
- **Context**: Walkthrough skips TrainingConfirmButton since Story 003 removed training option auto-selection.
- **Ceiling**: When authoritative training option selection is restored, restore `TrainingConfirmButton` walkthrough step.
- **Decision**: Keep. Downgraded walkthrough from authority verifier to smoke/visibility verifier per S4-03 boundary.

### 3. `tests/integration/ui/mvp_visual_walkthrough_runner.gd:45`
```
# ponytail: just verify match_pre is reachable, don't fuss about which button gets there
```
- **Context**: Match entry uses `ScreenManager.reset_to_screen("match_pre")` instead of button-driven navigation.
- **Ceiling**: When Home CTA button text is stable across all contract states, restore button-driven navigation.
- **Decision**: Keep. Valid simplification for smoke/visibility walkthrough.

## No-Action Items

- `src/` directory: 0 markers. No technical debt in production code.
- `TODO/FIXME/HACK/XXX`: 0 markers across entire codebase.

## Recommendations

None. Current debt posture is clean. Re-scan after next authority-contract or feature wave.
