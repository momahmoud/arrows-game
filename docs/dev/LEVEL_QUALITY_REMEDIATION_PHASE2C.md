# Level quality remediation, phase 2C (levels 351–400)

Status: **development candidate only.** Follow-on to
[LEVEL_QUALITY_REMEDIATION_PHASE2B.md](LEVEL_QUALITY_REMEDIATION_PHASE2B.md).
Uses the **production** campaign as baseline (not Phase 2A/2B binaries).
`assets/levels.bin` was not modified. Phase 1 / 1B / 2A / 2B artifacts were left
in place.

## Reproducing

```bash
flutter test test/candidates/phase2c_test.dart
```

Optional contact sheets (phone 366×600 harness):

```bash
OUT=build/candidates/phase2c_351_400
REPR=351,352,354,355,357,360,364,370,374,376,380,388,395,399,400
SPECIALS=353,357,360,364,367,371,374,378,381,385,388,392,395,399

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
# (omit THEMES=light so dark frames are also written)
```

Output under `build/candidates/phase2c_351_400/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate (production + 351–400) |
| `candidates.json` | Per-level roles, profiles, trap fairness, silhouette |
| `boards.txt` | ASCII boards |
| `campaign_audit.json` | Strict audit |
| `snapshots/original`, `candidate` | Phone 366×600 light (+ dark for candidates) |
| `sheet_representative.png`, `sheet_specials.png`, `sheet_specials_dark.png` | Contact sheets |

Code: `test/candidates/phase2c.dart`, `phase2c_test.dart`.

## Original baseline (Task 1)

From `build/level_quality.json` (production):

| Band | Type | n | Median arrows | Peel | Dead-end | Cell dp | Crowd |
|---|---|---|---|---|---|---|---|
| 301–350 | normal | 35 | 50 | 16 | 0.00 | 16.5 | 0.72 |
| **351–400** | **normal** | **36** | **49** | **18** | **0.00** | **16.5** | **0.73** |
| 401–450 | normal | 36 | 53 | 18 | 0.00 | 15.7 | 0.70 |
| 351–400 | boss | 7 | 114 | 30 | 0.00 | 8.7 | 0.74 |
| 351–400 | god | 7 | 132 | 24 | 0.00 | 8.7 | 0.81 |

Confirmed issues in production 351–400:

- Plateau continues: normals match neighbours (~49 arrows, peel ~18, dead ≈0).
- Almost no order deadlocks in random play; **L364 boss** is an outlier (dead **0.72**, peel **16**, open **27**).
- **L352** normal is shallow (peel **9**, open **19**).
- **L374** god opens very wide (**33**).
- **L395** god (`nestingDolls`) has **0** directional dots and **0** pairs — mechanic-empty for its slot.
- Specials remain size-driven (91–153 arrows) with crowding ~0.64–0.88 at ~8–13 dp.

Exact vs estimate: peel/opening/fill are exact under the exit rule; dead-end
rate is a 32-playout estimate; exhaustive dead-end absence is only proven when
reachability completes.

Special schedule (from `AppConstants.levelTypeFor`): bosses **357, 364, 371,
378, 385, 392, 399**; gods **353, 360, 367, 374, 381, 388, 395**.

## Design vs Phase 2A / 2B (Tasks 2–5, 9)

| Principle | Phase 2A | Phase 2B | Phase 2C |
|---|---|---|---|
| Role mix | Mostly trap/breather | chain / pairLock / trap / breather | **+ detour**; trap-free bossChain / godPair |
| Trap count (batch) | 49 | 28 | **13** |
| Median peel (candidate) | 10 | 12 | **12** |
| Median dead-end (all) | 0.34 | 0.19 | **0.00*** |
| Trap-level median dead | — | — | **0.34** |
| Seed salt | 22 | 33 | **44** |
| Baseline | production | production | **production** (not 2A/2B merge) |

\*Batch median is 0 because non-trap roles outnumber trap roles; trap levels
still target mild live deadlocks.

Reusable from earlier phases: reverse construction, outline bias,
`TrapFairness` with constructive solution-path fallback, byte-identical outside
the edit range, silhouette scoring.

Deliberately avoided: Phase 2A trap-majority; Phase 2B’s exact role schedule and
“always one trap on bossChain/godPair”; chasing a fixed ~0.35 dead-end rate;
merging prior candidate binaries.

### Role schedule

| Role | Levels (count) | Intent |
|---|---|---|
| breather | 355,363,370,377,384,391,398 (7) | Order-independent relief |
| chain | 351,356,362,368,375,382,389,396,400 (9) | Deep peel, detours, **no traps** |
| detour | 354,361,369,376,383,390,397 (7) | **New**: curved deflectors, no traps |
| pairLock | 358,365,372,379,386,393 (6) | Colour pairs as main dependency |
| trap | 352,359,366,373,380,387,394 (7) | One fair live trap (L352 rescue) |
| bossChain | 357,371,385,399 (4) | Peel-first bosses; **no traps** |
| bossTrap | 364,378,392 (3) | One fair climax trap (L364 rescue) |
| godPair | 353,367,381,395 (4) | Multi-pair climax; **no traps** (L395 restore) |
| godTrap | 360,374,388 (3) | One fair trap + dense deflectors |

Decade intent (not strictly harder each step):

| Decade | Emphasis |
|---|---|
| 351–360 | Introduce detour + chain; L352 trap rescue; godPair L353; bossChain L357 |
| 361–370 | Alternating detour/chain/breather; L364 bossTrap rescue |
| 371–380 | Deeper mid-band; L374 godTrap tightens production’s wide open |
| 381–390 | Mixed roles; dolphin/blowfish/dates specials |
| 391–400 | Breathers frame finish; L395 pair restore; L399 trap-free boss finale |

## Candidate vs original by decade

| Decade | Arrows o→c | Peel o→c | Dead o→c† | Traps | Notes |
|---|---|---|---|---|---|
| 351–360 | 54→28 | 24→13 | 0→0.00 | 3 | L352 peel 9→13 |
| 361–370 | 51→26 | 19→12 | 0→0.00 | 2 | L364 dead 0.72→0.31 |
| 371–380 | 52→31 | 20→14 | 0→0.00 | 4 | L374 open 33→12 |
| 381–390 | 53→30 | 21→11 | 0→0.00 | 2 | Mixed |
| 391–400 | 55→30 | 19→12 | 0→0.00 | 2 | L395 pairs 0→4 |

†Decade median dead can be 0 when half the decade is non-trap.

Batch medians: peel **12**; arrows **28**; crowd **0.16** (was **0.74**);
**13/13** traps fair. Max nearest arrow IoU **0.19**.

## Boss / God findings (Task 3)

| L | Role | Shape | Peel o→c | Open o→c | Dead o→c | Traps | Pairs |
|---|---|---|---|---|---|---|---|
| 353 | godPair | carouselHorse | 26→16 | 24→18 | 0→0 | 0 | 3 |
| 357 | bossChain | parallelogram | 25→17 | 20→11 | 0→0 | 0 | 2 |
| 360 | godTrap | diyaLamp | 24→14 | 27→13 | 0→0.38 | 1 | 2 |
| **364** | bossTrap | medal | **16→13** | **27→13** | **0.72→0.31** | 1 | 1 |
| 367 | godPair | owl | 35→16 | 15→13 | 0→0 | 0 | 3 |
| 371 | bossChain | wizard | 30→18 | 25→14 | 0→0 | 0 | 2 |
| **374** | godTrap | genie | 20→15 | **33→12** | 0→0.34 | 1 | 2 |
| 378 | bossTrap | apple | 40→15 | 15→8 | 0→0.28 | 1 | 1 |
| 381 | godPair | dolphin | 22→11 | 28→13 | 0→0 | 0 | 4 |
| 385 | bossChain | blowfish | 27→16 | 22→15 | 0→0 | 0 | 2 |
| 388 | godTrap | dates | 40→14 | 16→12 | 0→0.31 | 1 | 2 |
| 392 | bossTrap | wave | 31→16 | 19→14 | 0→0.22 | 1 | 1 |
| **395** | godPair | nestingDolls | 19→12 | 31→12 | 0→0 | 0 | **4** |
| 399 | bossChain | car | **35→13** | 13→18 | 0→0 | 0 | 2 |

Specials remain at ~8–13 dp (masks/grids unchanged). Crowding falls sharply.
Silhouettes are still hard to name at phone size; lower density and clearer
blocking help structure more than identity.

Preceding normals prepare specials: chains/detours before bossChain; traps
before bossTrap/godTrap; pairLocks before godPair (and L395 restore).

## Density, variety, duplicates (Task 5)

- Crowding typically falls from ~0.7+ to ~0.0–0.4.
- Max nearest arrow IoU **0.19**; no exact fingerprint duplicates in audit.
- Detour role adds curved-path practice without recirculating 2A/2B trap geometry.
- Useful shape recurrence kept via preserved `maskShape` / Boss–God schedule.
- L376 detour meets fill (~0.76) with few long arrows (14) — silhouette retained;
  play length may feel short; flagged for human playtesting.

## Validation (Tasks 6–7)

`flutter test test/candidates/phase2c_test.dart`: **9 of 9 passed.**

Also: `dart format` + `dart analyze` clean on phase2c files;
`flutter test --exclude-tags generator,campaign,slow,release,candidates`: **206 passed**.

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels **1–350** and **401–1000** byte-identical to production.
- Levels **351–400** differ; Phase 1 / 1B / 2A / 2B baselines still present and different.
- Role-mix test: non-trap roles outnumber trap roles; detour ≥6; traps ≤8.
- Strict audit: 1000 valid/solvable, 0 unverified, 0 fallback, 0 duplicates.
- Stored solution + DFS replay in `GameState` for every changed level.
- All 13 traps `TrapFairness.ok`; non-trap roles dead-end rate 0 (where required).
- Targeted: L352 peel > production; L364 dead < production; L395 pairs > 0.
- Determinism for 351, 370, 395.
- `assets/levels.bin` SHA-1: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

### Search limits

Reachability cap **200,000**. **14 specials** incomplete:
353, 357, 360, 364, 367, 371, 374, 378, 381, 385, 388, 392, 395, 399.
Traps on those boards were still proven via constructive solution path +
`GameState` deadlock. Other dead ends there are **unverified**, not “none”.

## Visual checks (Task 8)

- Viewport **366×600**, harness (not a device).
- Light: original + candidate for representative normals and all specials.
- Dark: candidate specials (`sheet_specials_dark.png`).
- Arabic RTL: **not** screenshot-tested; board is grid-centred / not locale-driven.
- Real-device testing: **not** performed.

Contact-sheet review: candidates show longer continuous paths and more negative
space while keeping mask outlines; specials remain dense at small cell sizes but
are less “texture” than production.

## Evaluation (Task 9)

| Question | Observation |
|---|---|
| More varied decisions? | Yes structurally: 9 roles including new detour; only 13 traps |
| Coherent complexity curve? | Decades mix breathers with peaks; not strictly escalating |
| Distinctive specials? | bossChain/godPair trap-free vs bossTrap/godTrap; L395 mechanics restored |
| Better readability? | Crowd 0.74→0.16; sheets show clearer corridors |
| Less repetitive structure? | Different salt/schedule than 2B; detour role unique to 2C |
| Trap frustration risk? | Lower than 2A/2B trap counts; still needs playtesting |
| Too-short puzzles? | Arrow counts lower than production; L376 is sparse; peel median 12 vs ~19 |

Do **not** claim improved enjoyment, retention, or engagement without players.

Remaining playtesting questions: whether trap-free bossChain/godPair feel
special enough vs production’s sheer size; whether peel ~11–15 feels substantial
after production’s longer peels; special readability at ~8 dp; whether to combine
2A+2B+2C later (not done here).

## Trade-offs

- Arrow counts and peels are lower than production size-driven specials by
  design (readability / distinctive decisions), not “harder by denser”.
- L399 bossChain peel **35→13**: preserves trap-free identity but loses
  production’s extreme peel depth.
- Incomplete reachability on all 14 specials limits deadlock exhaustiveness claims.
- Fill targets can be met with few long arrows (L376); depth and silhouette can
  diverge — evaluate together, not by arrow count alone.

## Files changed

- `test/candidates/phase2c.dart` (new)
- `test/candidates/phase2c_test.dart` (new)
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE2C.md` (this report)

Artifacts: `build/candidates/phase2c_351_400/`.
Full per-level tables: `candidates.json`.
