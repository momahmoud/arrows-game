# Level quality remediation, phase 2D (levels 401–450)

Status: **development candidate only.** Follow-on to
[LEVEL_QUALITY_REMEDIATION_PHASE2C.md](LEVEL_QUALITY_REMEDIATION_PHASE2C.md).
Uses the **production** campaign as baseline (not Phase 2A/2B/2C binaries).
`assets/levels.bin` was not modified. Earlier phase artifacts were left in place.

## Reproducing

```bash
flutter test test/candidates/phase2d_test.dart
```

Optional contact sheets (phone 366×600 harness):

```bash
OUT=build/candidates/phase2d_401_450
REPR=401,402,404,406,410,413,420,427,430,434,437,441,444,447,450
SPECIALS=402,406,409,413,416,420,423,427,430,434,437,441,444,448

BOARD_SNAPSHOT_BIN=assets/levels.bin \
  BOARD_SNAPSHOT_DIR=$OUT/snapshots/original \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light \
  BOARD_SNAPSHOT_LEVELS=$REPR,$SPECIALS \
  flutter test test/visual/board_snapshot_test.dart

BOARD_SNAPSHOT_BIN=$OUT/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=$OUT/snapshots/candidate \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light \
  BOARD_SNAPSHOT_LEVELS=$REPR,$SPECIALS \
  flutter test test/visual/board_snapshot_test.dart

BOARD_SNAPSHOT_BIN=$OUT/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=$OUT/snapshots/candidate \
  BOARD_SNAPSHOT_VIEWPORTS=phone \
  BOARD_SNAPSHOT_LEVELS=$SPECIALS \
  flutter test test/visual/board_snapshot_test.dart
```

Output under `build/candidates/phase2d_401_450/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate (production + 401–450) |
| `candidates.json` | Per-level roles, profiles, trap fairness, silhouette |
| `boards.txt` | ASCII boards |
| `campaign_audit.json` | Strict audit |
| `snapshots/original`, `candidate` | Phone 366×600 light (+ dark for candidates) |
| `sheet_representative.png`, `sheet_specials.png`, `sheet_specials_dark.png` | Contact sheets |

Code: `test/candidates/phase2d.dart`, `phase2d_test.dart`.

## Original baseline (Task 1)

From `build/level_quality.json` (production):

| Band | Type | n | Median arrows | Peel | Dead-end | Cell dp | Crowd |
|---|---|---|---|---|---|---|---|
| 351–400 | normal | 36 | 49 | 18 | 0.00 | 16.5 | 0.73 |
| **401–450** | **normal** | **36** | **53** | **18** | **0.00** | **15.7** | **0.70** |
| 451–500 | normal | 35 | 52 | 18 | 0.00 | 15.7 | 0.69 |
| 401–450 | boss | 7 | 119 | 23 | 0.00 | 8.2 | 0.81 |
| 401–450 | god | 7 | 176 | 33 | 0.00 | 9.2 | 0.80 |

Confirmed issues in production 401–450:

- Plateau continues vs 351–400 / 451–500 (~53 arrows, peel ~18, dead ≈0).
- **L434 boss** catastrophic: peel **3**, open **35**, dead **0.47**.
- **L427 boss**: dead **0.91**, peel **15**.
- **L413 boss**: peel **17** / open **37** (wide and shallow for a boss).
- **L406 boss**: open **52**.
- **L402 god** (dhow): **261** arrows, crowd **0.94**, open **39**.
- **L437 god** (pretzel): **0** directional dots / **0** pairs.
- Normals with observed dead ends: 410, 415, 438; shallow L447 peel **11**.

Exact vs estimate: peel/opening/fill are exact under the exit rule; dead-end
rate is a 32-playout estimate; exhaustive dead-end absence is only proven when
reachability completes.

Special schedule (`AppConstants.levelTypeFor`): bosses **406, 413, 420, 427,
434, 441, 448**; gods **402, 409, 416, 423, 430, 437, 444**.

## Design vs Phase 2A / 2C (Tasks 2–5, 10)

| Principle | Phase 2A | Phase 2C | Phase 2D |
|---|---|---|---|
| Role mix | Trap-heavy | +detour; trap-free bossChain/godPair | Same role set; **different schedule** |
| Trap count | 49 | 13 | **14** |
| Median peel | 10 | **12** | **13** |
| Median arrows | — | **28** | **31** |
| Median crowd | — | 0.16 | **0.19** |
| Seed salt | 22 | 44 | **55** |
| Peel scoring | Mild | Moderate | **Heavier** (`×0.35` + arrow duration term) |
| Thinning guard | — | — | Reject normals far below brief arrow target |

Phase 2C lesson adopted: varied roles, fair traps only, production baseline,
outline bias, constructive `TrapFairness`.

Phase 2C trade-off addressed: raise arrow/peel floors and score duration so
the batch does not simply repeat peel ~19→12 / arrows ~28. Result: peel
median **13** (vs 2C **12**), arrows **31** (vs **28**), still far clearer
than production crowd **0.74→0.19**.

Deliberately avoided: merging 2A/2B/2C binaries; chasing a fixed dead-end rate;
2A trap-majority; identical 2C breather/trap IDs.

### Role schedule

| Role | Levels (count) | Intent |
|---|---|---|
| breather | 404,412,421,429,433,442,447 (7) | Relief; includes peel-resistant masks |
| chain | 401,407,414,422,428,435,449,450 (8) | Deep peel, no traps |
| detour | 405,411,419,426,436,440,446 (7) | Curved deflectors, duration preserved |
| pairLock | 403,410,418,425,432,439,445 (7) | Colour pairs; order-independent |
| trap | 408,415,417,424,431,438,443 (7) | One fair live trap |
| bossChain | 413,434,448 (3) | Peel-first; L413/L434 rescues |
| bossTrap | 406,420,427,441 (4) | One fair trap; L406/L427 rescues |
| godPair | 409,423,437,444 (4) | Multi-pair; L437 restore |
| godTrap | 402,416,430 (3) | One trap; L402 readability rescue |

Decade intent (peaks and relief, not strictly escalating):

| Decade | Emphasis |
|---|---|
| 401–410 | Chain open; L402 godTrap density rescue; L406 open rescue |
| 411–420 | Mixed; L413 bossChain; L416 godTrap |
| 421–430 | Mid-band depth; L427 bossTrap fairness |
| 431–440 | L434 candy peel rescue; L437 pair restore; breathers on hard masks |
| 441–450 | Boss/god finish; chains at 449–450 |

## Candidate vs original by decade

| Decade | Arrows o→c | Peel o→c | Traps | Notes |
|---|---|---|---|---|
| 401–410 | 55→31 | 21→13 | 3 | L402 261→57 arrows, crowd 0.94→0.12 |
| 411–420 | 58→30 | 20→13 | 4 | L413 open 37→17 |
| 421–430 | 64→36 | 21→14 | 3 | Highest arrow decade |
| 431–440 | 53→28 | 18→11 | 2 | L434 peel 3→11; L437 pairs 0→4 |
| 441–450 | 59→33 | 22→13 | 2 | Finish with chains |

Batch medians: peel **13**, arrows **31**, crowd **0.19**; **14/14** traps fair.
Max nearest arrow IoU **0.21**. Trap-level median dead-end **0.34**.

## Boss / God findings (Task 3)

| L | Role | Peel o→c | Open o→c | Dead o→c | Traps | Notes |
|---|---|---|---|---|---|---|
| **402** | godTrap | 40→16 | 39→10 | 0→0.22 | 1 | Extreme density rescued |
| 406 | bossTrap | 32→14 | **52→17** | 0→0.28 | 1 | Opening capped |
| 409 | godPair | 32→16 | 37→15 | 0→0 | 0 | Pair climax |
| **413** | bossChain | 17→16 | **37→17** | 0→0 | 0 | Tighter open |
| 416 | godTrap | 34→16 | 44→10 | 0→0.38 | 1 | |
| 420 | bossTrap | 23→17 | 33→15 | 0→0.28 | 1 | Strong peel kept |
| 423 | godPair | 33→15 | 35→14 | 0→0 | 0 | |
| **427** | bossTrap | 15→12 | 29→16 | **0.91→0.34** | 1 | Fairer deadlock |
| 430 | godTrap | 36→15 | 16→11 | 0→0.31 | 1 | |
| **434** | bossChain | **3→11** | **35→14** | 0.47→0 | 0 | Critical rescue |
| **437** | godPair | 17→**18** | 29→14 | 0→0 | 0 | Pairs restored (4) |
| 441 | bossTrap | 33→17 | 21→12 | 0→0.19 | 1 | |
| 444 | godPair | 29→15 | 18→9 | 0→0 | 0 | |
| 448 | bossChain | 32→15 | 26→17 | 0→0 | 0 | Trap-free finale |

Specials remain at ~8–12 dp (masks unchanged). Crowding falls sharply.
Neighbouring chains/detours/pairLocks prepare specials without copying 2C IDs.

## Density, variety, duplicates (Tasks 5–6)

- Crowding typically falls from ~0.7+ to ~0.1–0.4.
- Max nearest arrow IoU **0.21**; no exact fingerprint duplicates in audit.
- Peel-resistant masks (433, 442, 447) assigned as breathers rather than forced
  into deep-chain briefs.
- Contact sheets show clearer corridors while silhouettes remain recognizable.
- Cell-size limits on specials are mask/grid invariants — not “solved” by
  thinning alone; documented rather than claimed fixed.

## Validation (Tasks 7–8)

`flutter test test/candidates/phase2d_test.dart`: **9 of 9 passed.**

Also: `dart format` + `dart analyze` clean on phase2d files;
`flutter test --exclude-tags generator,campaign,slow,release,candidates`.

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels **1–400** and **451–1000** byte-identical to production.
- Levels **401–450** differ; Phase 1 / 1B / 2A / 2B / 2C baselines still present.
- Role-mix + duration guards: non-trap majority; median arrows ≥30.
- Strict audit: 1000 valid/solvable, 0 unverified, 0 fallback, 0 duplicates.
- Stored solution + DFS replay in `GameState` for every changed level.
- All 14 traps `TrapFairness.ok`; non-trap roles dead-end rate 0 where required.
- Targeted: L434 peel ≥8; L437 pairs >0; L427 dead < production; L413 open↓;
  L402 crowd <0.6 and fewer arrows.
- Determinism for 401, 434, 437.
- `assets/levels.bin` SHA-1: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

### Search limits

Reachability cap **200,000**. **13 specials** incomplete:
402, 406, 409, 413, 416, 420, 423, 427, 430, 437, 441, 444, 448.
(L434 candy completed under the cap.) Traps on incomplete boards were still
proven via constructive solution path + `GameState` deadlock. Other dead ends
there are **unverified**, not “none”.

## Visual checks (Task 6 / 9)

- Viewport **366×600**, harness (not a device).
- Light: original + candidate for representatives and all specials.
- Dark: candidate specials (`sheet_specials_dark.png`).
- Arabic RTL: **not** screenshot-tested.
- Real-device testing: **not** performed.

Sheets show denser production “texture” vs clearer candidate corridors; L402 /
L434 / L406 rescues are visually obvious.

## Evaluation vs Phase 2C (Task 10)

| Metric | Production 401–450 | Phase 2C batch | Phase 2D batch |
|---|---|---|---|
| Median peel | ~18–20 mixed | 12 | **13** |
| Median arrows | ~53–55 | 28 | **31** |
| Median crowd | ~0.74 | 0.16 | **0.19** |
| Trap count | ~0 live | 13 | **14** |
| Decision variety | Low (dead≈0) | High (9 roles) | High (9 roles, new IDs) |

Improvements independent of a single metric: L434 peel rescue, L437 mechanics
restore, L402/L406 readability, fairer L427, slightly fuller boards than 2C
without returning to production crowding.

Remaining questions for playtesting: whether peel 11–15 feels long enough after
production’s longer peels; whether breathers on peel-resistant masks feel too
easy; special readability at ~8 dp; whether to combine mid-campaign candidates
later (not done here).

Do **not** claim improved enjoyment, retention, or engagement without players.

## Trade-offs

- Peel and arrow counts remain below production size-driven specials by design
  (readability / distinctive decisions), but are higher than Phase 2C’s median.
- L434 still cannot match production-sized boss peels (mask resists deep peel
  under reverse construction); **3→11** is the achievable rescue.
- Incomplete reachability on 13 specials limits exhaustive deadlock claims.
- Some breathers (433/442/447) exist because deep-chain briefs failed — honest
  role reassignment rather than weakening validation.

## Files changed

- `test/candidates/phase2d.dart` (new)
- `test/candidates/phase2d_test.dart` (new)
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE2D.md` (this report)

Artifacts: `build/candidates/phase2d_401_450/`.
Full per-level tables: `candidates.json`.
