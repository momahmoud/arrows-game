# First-500 quality candidate — human playtest worksheet

Status: **development playtest plan.** Production `assets/levels.bin` stays
untouched. Candidate:
`build/candidates/first_500_quality/levels_candidate.bin`.

Companion audit: `LEVEL_QUALITY_FIRST_500_REMEDIATION.md`.  
Results (fill only after real sessions):
`LEVEL_QUALITY_FIRST_500_PLAYTEST_RESULTS.md`.

**Do not invent scores or completion times.** Empty cells mean “not yet
played.” Do not start 501–1000 remediation until the decision gate below is
reviewed.

---

## 1. How to load the candidate (dev only)

### A. Interactive sandbox (preferred for humans)

Requires a host-readable candidate file (desktop / simulator with workspace
path, or an absolute path on device storage):

**Desktop / macOS** (host path works):

```bash
flutter run --dart-define=ENABLE_FIRST500_PLAYTEST=true --dart-define=FIRST500_PLAYTEST_BIN=build/candidates/first_500_quality/levels_candidate.bin
```

**Android emulator / device** (host-relative `build/…` is invisible to the
app — push the bin first):

```bash
adb push build/candidates/first_500_quality/levels_candidate.bin \
  /data/local/tmp/first_500_levels_candidate.bin

flutter run --dart-define=ENABLE_FIRST500_PLAYTEST=true \
  --dart-define=FIRST500_PLAYTEST_BIN=/data/local/tmp/first_500_levels_candidate.bin
```

The playtest hub also auto-checks `/data/local/tmp/`, `/sdcard/Download/`, and
`/storage/emulated/0/Download/` for `first_500_levels_candidate.bin` after a
push (hot-restart after pushing).

Then: **Settings → First-500 playtest (dev)**.

- Toggle **Production** vs **Candidate**.
- Jump to any level ID (or use priority chips).
- Progress, coins, and unlocks in the sandbox are **isolated** (null prefs /
  memory-only). Leaving the sandbox returns to the real campaign unchanged.
- Arrow mechanics, timers, deadlocks, and power-ups use the real `GameScreen`.
- Release builds never expose the entry (`enableFirst500Playtest` is false).
- Candidate is **not** registered in `pubspec` assets.

### B. Screenshot harness (visual A/B, no progress impact)

```bash
OUT=build/candidates/first_500_quality/playtest_snapshots
LEVELS=3,4,12,24,25,50,97,210,217,220,230,239,250,251,255,270,300,301

BOARD_SNAPSHOT_BIN=assets/levels.bin \
  BOARD_SNAPSHOT_DIR=$OUT/original \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light \
  BOARD_SNAPSHOT_LEVELS=$LEVELS \
  flutter test test/visual/board_snapshot_test.dart

BOARD_SNAPSHOT_BIN=build/candidates/first_500_quality/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=$OUT/candidate \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light,dark \
  BOARD_SNAPSHOT_LEVELS=$LEVELS \
  flutter test test/visual/board_snapshot_test.dart
```

Harness does not write player saves. Viewport is typically **366×600**, not a
substitute for device touch testing.

### C. What this does *not* do

- No production Settings toggle without the dart-define.
- No automatic campaign swap for normal players.
- No remote analytics / tester PII collection.
- No solvability or trap-rule bypass.

---

## 2. Playtest protocol

1. Explain controls only (tap arrow to slide out; blocked paths shake; power-ups
   exist). **Do not** reveal intended solutions before the first attempt.
2. Same script for original and candidate when both are tested.
3. Balance order when feasible (half of testers see candidate first on a given
   level; alternate segments).
4. Record failures, retries, hints/power-ups, duration, and comments the same
   way every session.
5. Watch whether the player notices risky moves before committing.
6. Log **accidental taps / visual confusion** separately from **puzzle
   mistakes**.
7. Let players finish the short sequence around a priority ID so pacing can be
   judged (adjacent levels matter).
8. Collect short feedback after each segment (not only at the end).

Pilot group: small and varied is enough to find blockers — **not** a
statistical sample of all players.

Anonymous session labels only (e.g. `S1`, `S2`). No names, contacts, or
precise locations.

---

## 3. Rating scale (subjective — separate from measurements)

| Score | Clarity | Fairness | Challenge | Visual |
|---|---|---|---|---|
| 1 | Confusing | Punitive / broken | Trivial | Unreadable |
| 2 | Hard to parse | Often unfair | Too easy | Frequent mis-taps |
| 3 | OK with effort | Mixed | Slightly off | Crowded but OK |
| 4 | Clear after a beat | Mistakes feel earned | Fits position | Readable |
| 5 | Immediately clear | Fair throughout | Spot-on | Crisp |

**Measured:** completion Y/N, approx. time, retries, hints/power-ups used.  
**Do not** treat time alone as difficulty.

---

## 4. Priority set and rationale

### Priority 0 — must test first

| Levels | Differs? | Main question |
|---|---|---|
| 3–4 | 4 = Phase 1B | Tutorial → regular play handoff |
| 12 | Candidate | First intentional trap fair / readable? |
| 24–25 | 24 = 1B; 25 = prod | Early special → mid production |
| 50, 97, 230, 239 | Candidate | Repairs: depth without frustration |
| 210, 217, 220 | Candidate | Former wide-open specials |
| 250–251 | 251 = 2A | Duration/complexity cliff |
| 255, 270 | Candidate (2A) | Trap-heavy section feel |
| 300–301 | Both changed vs prod mid | Recovery after Phase 2A |

Play **adjacent** levels (±1) when judging pacing. For unchanged IDs, evaluate
the **transition**, not a fake A/B.

### Priority 1 — duration and rhythm

301, 320, 346 · 376, 399, 434 · 463, 474, 481, 487, 488 · boundaries
350–351, 400–401, 450–451, 500–501.

### Priority 2 — visual clarity

10, 24 · representative Boss/God · dense boards · trap-free chains ·
pair-lock · breathers. Check arrow direction, silhouette, crowded heads,
touch accuracy.

---

## 5. Session header (copy per tester)

| Field | Value |
|---|---|
| Session label | |
| Build / commit | |
| Environment | harness / emulator / device (model) |
| Theme | light / dark / both |
| Locale | en / ar / other |
| Source order | production first / candidate first / mixed |
| Notes | |

---

## 6. Level worksheet template

Copy one block per level attempt. Mark version **O** (original/production) or
**C** (candidate).

```
### L____  version: O / C   type: normal / boss / god / tutorial
Session: ____   Segment: ____

Instructions given: (same script?) Y/N
Objective this attempt: _______________________________

RESULT
- Completed: Y / N / abandoned
- Approx. time: ____ s
- Retries (full restarts): ____
- Hints used: ____   Other power-ups: ____
- Intended idea understandable: Y / N / unsure
- Mistake/deadlock felt fair: Y / N / n/a
- Difficulty feel: too easy / appropriate / too hard
- Duration feel: too short / appropriate / repetitive
- Accidental taps / visual confusion: ________________
- Puzzle mistakes (logic): ___________________________

RATINGS (1–5)
Clarity ____  Fairness ____  Challenge ____  Visual ____

Observations:
_____________________________________________________

Proposed action: accept / watch / refine / hold / more evidence
```

### Pre-filled Priority 0 rows

Use empty measured/subjective fields until played.

| ID | Ver | Campaign note | Objective | Done? | Time | Retries | Hints | Clarity | Fair | Chall | Visual | Action |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 | O=C | Tutorial | Transition into L4 | | | | | | | | | |
| 4 | C | Phase 1B | Natural after tutorial? | | | | | | | | | |
| 4 | O | Prod compare | A/B if testing both | | | | | | | | | |
| 12 | C | First trap | Fair & readable? | | | | | | | | | |
| 12 | O | Prod trap | Compare telegraph | | | | | | | | | |
| 24 | C | Special | Silhouette + exit | | | | | | | | | |
| 25 | O=C | Mid prod | After special OK? | | | | | | | | | |
| 50 | C/O | Repair | Depth vs frustrate | | | | | | | | | |
| 97 | C/O | Repair | Same | | | | | | | | | |
| 210 | C/O | Open rescue | Readable special | | | | | | | | | |
| 217 | C/O | Open rescue | Same | | | | | | | | | |
| 220 | C/O | Open rescue | Same | | | | | | | | | |
| 230 | C/O | Repair | Same | | | | | | | | | |
| 239 | C/O | Worst dead | Fair deadlock | | | | | | | | | |
| 250 | O=C | Before cliff | Baseline duration | | | | | | | | | |
| 251 | C | 2A start | Cliff too abrupt? | | | | | | | | | |
| 255 | C | 2A trap | Trap telegraph | | | | | | | | | |
| 270 | C | 2A trap | Fatigue sample | | | | | | | | | |
| 300 | C | 2A end | Still engaging? | | | | | | | | | |
| 301 | C | 2B start | Recovery feel | | | | | | | | | |

Add Priority 1–2 rows the same way during the session. Extra IDs discovered
in play go in an “Additional levels” section at the bottom of the results doc.

---

## 7. Phase 2A trap-fatigue checklist

Candidate keeps **49 traps** in 251–300. Observe consecutive traps and a
trap-free relief stretch (prefer early 2B).

| Question | Observation (fill in session) |
|---|---|
| Similar layouts feel predictable? | |
| Risky taps understood before commit? | |
| Deadlock + recovery communication clear? | |
| Mistake count feels fair vs punitive? | |
| Trap-free levels give enough relief? | |
| Hesitation on every move (“everything is a trap”)? | |
| IDs to revisit in a 2A refinement pass | |

Do **not** auto-remove traps here. Any change needs the same solvability /
trap-fairness validation as current candidates.

---

## 8. Duration / difficulty checklist

Static medians (from integration report): Phase 2A ~10 peel; 2B–2E ~12–13;
production often ~18–20 in those bands. Shorter ≠ worse.

| Question | Notes |
|---|---|
| Meaningful decisions remain? | |
| Completion still satisfying? | |
| Challenge fits campaign position? | |
| Campaign advances too quickly? | |
| Triviality (not just fewer arrows)? | |
| IDs needing duration refinement | |

---

## 9. Visual QA checklist

| Check | Harness | Emulator | Physical device | Pass/Fail/Skip |
|---|---|---|---|---|
| Arrowhead / direction recognition | | | | |
| Touch accuracy near neighbors | | | | |
| Board scaling / clipping | | | | |
| Small-cell specials (e.g. 10, 24) | | | | |
| Light theme | | | | |
| Dark theme | | | | |
| Arabic RTL layout | | | | |
| Path render vs tap hit-test | | | | |

Only mark Pass if that environment was actually used.

---

## 10. Decision gate (before 501–1000)

Combine **human observations** with the existing structural/solvability audit.
Do **not** accept on ratings or sample size alone.

| Outcome | When |
|---|---|
| **Accept** | No critical fairness/usability blockers; remaining differences acceptable or documented; audit still clean |
| **Refine** | Specific IDs/batches need targeted fixes + revalidation (e.g. 2A fatigue, shorts, cliff) |
| **Hold** | Critical unfair deadlocks, severe visual/touch issues, or major pacing problems unresolved |

**Gate rule:** Do not begin quality remediation for levels **501–1000** until
this playtest gate is completed and reviewed.

Pending human sessions → gate status remains **Hold (awaiting playtest)**.
