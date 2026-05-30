# GDScript Typed Dictionary Audit Design

Date: 2026-05-30

## Problem

Entering the team screen from `prototypes/little-football-town-vertical-slice/vertical_slice_main.tscn` can fail in `screens/team_screen.gd` with:

`Trying to assign a dictionary of type "Dictionary" to a variable of type "Dictionary[String, Nil]".`

The immediate failure is caused by assigning an untyped runtime dictionary, or a value pulled from `Variant`, into a variable declared as `Dictionary[String, Variant]`. The same pattern appears in prototype screens, session code, tests, and some runtime boundary code.

## Goal

Remove this class of typed collection runtime errors across `src/`, `tests/`, and `prototypes/` without weakening the core system contracts that already use typed dictionaries to document payload shape.

## Non-Goals

- Do not rewrite the data model away from dictionaries.
- Do not globally replace `Dictionary[String, Variant]` with plain `Dictionary`.
- Do not clean unrelated warnings unless they block verification.
- Do not change gameplay formulas, balance values, screen flow, or save semantics.

## Scope

Audit all GDScript files under:

- `src/`
- `tests/`
- `prototypes/`

Fix unsafe typed collection boundaries, especially:

- Assigning `Variant` values to `Dictionary[String, Variant]`.
- Assigning `Dictionary.get(..., {})` results to typed dictionaries.
- Iterating untyped arrays with typed dictionary loop variables.
- Assigning duplicated dictionaries from untyped sources to typed variables.
- Passing signal payloads or serialized payloads into typed APIs.
- Returning untyped literal dictionaries from functions declared as `Dictionary[String, Variant]` where Godot does not preserve the expected runtime type.

## Approach

Use boundary normalization instead of global type weakening.

Inside core systems, keep `Dictionary[String, Variant]` where it expresses an API contract. When input crosses from an untyped source into a typed contract, convert it through a local helper or an existing normalization helper such as `_to_string_variant_dictionary()`.

In UI and prototype presentation code, use plain `Dictionary` for local view-only data when the value is only read for labels, list metadata, or button state. This avoids unnecessary runtime typed dictionary assignments at volatile `Variant` boundaries.

In tests, keep typed dictionaries where they validate production APIs, but convert literal and fixture payloads explicitly before calling typed APIs.

## Components

### Audit Script or Search Pass

Use targeted search patterns to identify risky sites:

- `Dictionary[String, Variant] =`
- `for .*: Dictionary[String, Variant] in`
- `.get("...", {})`
- `.duplicate(true)` assigned to typed variables
- typed dictionary return functions returning `{ ... }`

Manual review decides whether each site should be normalized, weakened locally, or left unchanged.

### Conversion Helpers

Prefer existing helper functions in the owning module. If a module lacks a helper and repeatedly needs one, add a small private helper:

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		for key: Variant in value.keys():
			typed_dictionary[String(key)] = value[key]
	return typed_dictionary
```

Do not introduce a global utility module unless the audit shows repeated cross-module duplication that cannot be kept local cleanly.

### Prototype Screens

Prototype screens should not require typed dictionaries for local display data. They may read plain dictionaries returned from session view models, then coerce individual scalar values with `String()`, `int()`, `float()`, and `bool()`.

### Runtime Systems

Runtime systems should retain typed return contracts. They should normalize external payloads at the boundary and avoid directly assigning untyped nested dictionaries from `.get()` to typed variables.

### Tests

Tests should exercise the corrected boundaries by running the existing unit and integration scripts that cover save, time, player development, match, economy, and prototype flow where practical.

## Error Handling

When a value expected to be a dictionary is not a dictionary, conversion helpers return an empty typed dictionary. Existing caller logic should then fall back through current default handling.

This preserves current behavior for missing optional payloads while preventing runtime type assignment errors.

## Verification

Verification must include:

- Launching or running the reported vertical slice scene: `res://prototypes/little-football-town-vertical-slice/vertical_slice_main.tscn`.
- Exercising the team screen path far enough to confirm `team_screen.gd` no longer fails.
- Running relevant Godot test scripts or project-level test runners available in the repository.
- Re-running targeted searches to confirm known unsafe patterns were reviewed.

If full interactive verification is not possible through available tooling, document the limitation and provide the strongest automated evidence available.

## Risks

- Typed dictionary fixes can hide deeper shape mismatches if all invalid input becomes empty dictionaries. To reduce this risk, only normalize at known boundaries and preserve scalar conversions at use sites.
- Tests may include intentionally untyped payloads. These should be converted only where the target API requires typed dictionaries.
- The untracked `prototypes/training-match-loop-vertical-slice/` directory mirrors the reported prototype and may contain the same issue. It should be audited, but its untracked status must be preserved unless the user explicitly wants it added to version control.
