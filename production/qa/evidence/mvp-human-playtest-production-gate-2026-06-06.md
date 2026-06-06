# MVP Human Playtest — Production Gate Recovery — 2026-06-06

**Status**: Draft template — not yet executed  
**Purpose**: Clear remaining Production gate blockers by collecting human-observed evidence for:

- Vertical slice playtest completion
- Core fun validation
- Core fantasy validation

## Existing Automated Evidence

- `mvp_visual_walkthrough`: PASS
- Route sanity: PASS
- No automated route blockers detected

## Critical Route Under Test

`Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home`

## Minimum Session Count

- **Required to attempt gate clear**: 3 valid observed sessions
- All sessions should use the same candidate build / commit
- Do not count developer self-tests
- If a session is invalidated by setup error or unrelated technical failure before the route begins, rerun and replace it

## Participant Profile

- 3 individual participants
- At least 2 participants must be first-time players of this build
- At least 1 participant should be comfortable with football themes or management sims
- Participants should be PC mouse/keyboard users
- Avoid implementation team members if possible

## Setup

- **Build / Commit**: [fill in]
- **Platform**: Windows PC
- **Input**: Mouse + keyboard
- **Start State**: Clean boot into the intended MVP entry state
- **Observer**: QA / producer / designer taking notes
- **Observer Rule**: Do not explain UI, goals, or next steps unless the participant is blocked for more than 30 seconds
- **Capture**: Timestamped notes required; screen recording optional
- **Target Session Length**: 10–15 minutes

## Test Script

1. Read this prompt verbatim:

   > Please play as if you just opened the game. Try to inspect your squad, improve a player, and then play through the next match. Please think out loud while you play.

2. Start the participant at **Home**.
3. Ask the participant to continue naturally through the route without guidance:
   - Home
   - Roster
   - Player Detail
   - Training
   - Home
   - Match Pre
   - Match Live
   - Match Result
   - Home
4. The observer remains silent unless the participant is blocked for **>30s**.
5. Record any hesitation, backtracking, confusion, or intervention at the exact step.
6. After the participant returns to **Home**, ask the post-test questions exactly as written.

## Observation Checklist

Mark each item as **Pass / Warning / Blocker** with a short note.

- Participant noticed a clear next action on **Home**
- Participant found **Roster** without help
- Participant selected a player and understood they were on **Player Detail**
- Participant found and completed **Training** without help
- Participant returned to **Home** without confusion
- Participant started **Match Pre** without help
- Participant understood that **Match Live** was progressing
- Participant understood the outcome shown on **Match Result**
- Participant returned from **Match Result** to **Home**
- Participant could describe at least one decision they made
- Participant showed at least one positive or engaged reaction during the route
- Observer intervention was required
- Any crash, softlock, dead button, missing data, unreadable UI, or broken transition occurred

## Post-Test Questions

Ask exactly these 3 questions:

1. **Core Fantasy**  
   On a scale of 1–5, how much did this feel like managing a small football club? Why?

2. **Route Clarity**  
   On a scale of 1–5, how easy was it to go from squad management to finishing the match without help? Where, if anywhere, did you hesitate?

3. **Core Fun**  
   Based on this slice alone, would you want to play another in-game cycle or match? Why or why not?

## Pass / Fail Criteria

### Pass

The gate can be recommended as cleared only if all of the following are true:

- 3/3 valid sessions completed the full route
- 0 crashes, softlocks, or progression blockers occurred
- 0 sessions required observer explanation to continue the critical path
- At least 2/3 participants scored **Core Fantasy** at **4/5 or higher**
- At least 2/3 participants answered **Core Fun** positively
- No repeated blocker or major confusion point appeared in the same route step across 2 or more sessions

### Fail

The gate remains blocked if any of the following are true:

- Fewer than 3 valid observed sessions were completed
- Any participant failed to complete the route
- Any participant required observer explanation to recover the critical path
- Any S1/S2 issue occurred during the playtest
- Fewer than 2 participants scored **Core Fantasy** at 4/5 or higher
- Fewer than 2 participants answered **Core Fun** positively
- The same blocker or major confusion point appeared in 2 or more sessions

## Allowed Warnings

These should be logged, but do not fail the gate on their own if the route still completes cleanly:

- Brief hesitation under 30 seconds on a screen
- One self-corrected backtrack
- Minor confusion about a stat, label, or copy text
- Minor uncertainty about match details after the participant still completes the route
- One non-critical polish issue, such as layout, wording, or visual clarity

## Blocker Criteria

Any of the following is a blocker for that session:

- Participant is stuck on the critical path for more than 30 seconds
- Observer must explain where to click or what to do next
- Crash, softlock, dead-end, broken button, or missing screen transition
- Participant cannot tell how to continue from a required route step
- Training or match flow appears completed to the participant but the route cannot actually proceed
- Any S1/S2 bug appears during the session

## Exact Evidence Needed

To count as Production gate evidence, this package must include:

- This completed evidence file
- 3 completed single-session records
- Build version and commit hash used for all sessions
- Participant profile for each session
- Route completion result for each session
- Timestamped notes for any hesitation, warning, or blocker
- Raw answers to all 3 post-test questions
- Aggregate verdict summary
- QA recommendation: **Pass / Fail / Retest**
- Optional: recording filename or link, if captured

---

## Single-Session Record Template

### Session [01/02/03]

- **Date / Time**:
- **Build / Commit**:
- **Observer**:
- **Participant ID / Initials**:
- **Participant Profile**:
- **First-time player of this build?** Yes / No
- **Football / management sim familiarity**: Low / Medium / High
- **Session Duration**:
- **Route Completed?** Yes / No
- **Observer Intervention Needed?** Yes / No

#### Route Notes

| Step | Completed without help? | Warning / Blocker | Notes |
|---|---|---|---|
| Home |  |  |  |
| Roster |  |  |  |
| Player Detail |  |  |  |
| Training |  |  |  |
| Home (return) |  |  |  |
| Match Pre |  |  |  |
| Match Live |  |  |  |
| Match Result |  |  |  |
| Home (final) |  |  |  |

#### Observation Checklist Summary

- Clear next action on Home:
- Found Roster without help:
- Understood Player Detail:
- Completed Training without help:
- Returned Home without confusion:
- Started Match Pre without help:
- Understood Match Live:
- Understood Match Result:
- Returned to Home:
- Described a meaningful decision:
- Positive or engaged reaction observed:
- Crash / softlock / broken navigation:
- Other notes:

#### Post-Test Answers

- **Q1 — Core Fantasy (1–5 + why)**:
- **Q2 — Route Clarity (1–5 + where hesitation occurred)**:
- **Q3 — Core Fun (Would play another cycle/match? Why / why not)**:

#### Session Verdict

- **Result**: Pass / Warning / Blocker
- **Key Issue(s)**:
- **Key Quote(s)**:

---

## Aggregate Verdict Template

## Aggregate Results

- **Total Valid Sessions**:
- **Route Completed**: [x/3]
- **Sessions With Observer Intervention**: [x/3]
- **Core Fantasy >= 4/5**: [x/3]
- **Core Fun Positive**: [x/3]
- **Repeated Confusion Points**:
- **S1/S2 Issues Seen**:
- **Open Warnings**:
- **Open Blockers**:

## Gate Verdict

- **Verdict**: Pass / Fail / Retest
- **QA Recommendation**:
- **Reason**:

## Sign-off

- **Prepared by**:
- **Date**:
- **Build / Commit Verified**:
