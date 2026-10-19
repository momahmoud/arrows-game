# Level quality remediation, phase 2E (levels 451–500)

Status: **development candidate only.** Follow-on to
[LEVEL_QUALITY_REMEDIATION_PHASE2D.md](LEVEL_QUALITY_REMEDIATION_PHASE2D.md).
Uses the **production** campaign as baseline (not Phase 2A–2D binaries).
`assets/levels.bin` was not modified. Earlier phase artifacts were left in place.

## Reproducing

```bash
flutter test test/candidates/phase2e_test.dart
```

Optional contact sheets (phone 366×600 harness):

```bash
OUT=build/candidates/phase2e_451_500
REPR=451,455,460,462,470,474,476,479,483,490,491,495,497,499,500
SPECIALS=451,455,458,462,465,469,472,476,479,483,486,490,493,497,500

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

Output under `build/candidates/phase2e_451_500/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate (production + 451–500) |
| `candidates.json` | Per-level roles, profiles, trap fairness, silhouette |
| `boards.txt` | ASCII boards |
| `campaign_audit.json` | Strict audit |
| `snapshots/original`, `candidate` | Phone 366×600 light (+ dark for candidates) |
| `sheet_representative.png`, `sheet_specials.png`, `sheet_specials_dark.png` | Contact sheets |

Code: `test/candidates/phase2e.dart`, `phase2e_test.dart`.

## Original baseline (Task 1)

From `build/level_quality.json` (production; SHA-1
`bfac49331846e1cd4f588d4a08007fbacc8a3d68`):

| Band | Type | n | Median arrows | Peel | Short (&lt;12) | Dead-end | Cell dp | Crowd |
|---|---|---|---|---|---|---|---|---|
| 401–450 | normal | 36 | 53 | 18 | 1 | 0.00 | 15.7 | 0.70 |
| **451–500** | **normal** | **35** | **52** | **18** | **2** | **0.00** | **15.7** | **0.69** |
| 501–550 | normal | 36 | 52 | 16 | 3 | 0.00 | 15.7 | 0.71 |
| 451–500 | boss | 7 | 119 | 28 | 0 | 0.00 | 8.7 | 0.77 |
| 451–500 | god | 8 | 119 | 31 | 0 | 0.00 | 8.7 | 0.75 |

Confirmed issues in production 451–500:

- Plateau continues vs neighbours (~52 arrows, peel ~18, dead ≈0).
- **15 specials** this band (8 gods + 7 bosses) — denser special cadence.
- **L490 boss** (worm): peel **13**, only 68 arrows, small mask — shallow for boss.
- **L491** peel **11**; **L495** peel **9**; **L460** peel **12**.
- **L476** / **L479** opens **33**.
- Crowding on specials often 0.75–0.84 at ~8–11 dp.

Exact vs estimate: peel/opening/fill are exact under the exit rule; dead-end
rate is a 32-playout estimate; exhaustive dead-end absence is only proven when
reachability completes.

Special schedule (`AppConstants.levelTypeFor`): bosses **455, 462, 469, 476,
483, 490, 497**; gods **451, 458, 465, 472, 479, 486, 493, 500**.

## Design vs Phase 2C / 2D (Tasks 2–3, 11)

| Principle | Phase 2C | Phase 2D | Phase 2E |
|---|---|---|---|
| Seed salt | 44 | 55 | **66** |
| Role schedule | Unique | Unique | **Unique** (not 2D+50) |
| Breathers | 7 | 7 | **9** (honest peel-resistant) |
| Chains | 9 | 8 | **5** (only where deep peel holds) |
| Median peel | 12 | 13 | **13** |
| Peel p10 / p90 | — | 10 / 16 | **11 / 17** |
| Short peel (&lt;11) | — | ~6 | **5** |
| Median arrows | 28 | 31 | **31** |
| Median crowd | 0.16 | 0.19 | **0.19** |
| Traps | 13 | 14 | **15** |

Phase 2D lesson adopted: duration-weighted scoring, thinning guards, production
baseline, constructive `TrapFairness`, outline bias.

Phase 2D trade-off addressed **partially**: median peel matches 2D (13), but
the **distribution** improves (higher p10/p90, fewer short boards). Raising the
median further toward production’s ~18–20 while keeping crowd ~0.2 remains
mask-limited under reverse construction — documented rather than faked.

Deliberately avoided: copying 2D IDs; filling every mask cell; weakening
`TrapFairness`; claiming deep-chain roles on peel-resistant masks.

### Role schedule

| Role | Levels (count) | Intent |
|---|---|---|
| breather | 454,460,463,474,481,491,492,496,499 (9) | Relief + honest peel-resistant |
| chain | 452,459,466,471,489 (5) | Deep peel only where achievable |
| detour | 453,461,468,475,480,484,488 (7) | Curved deflectors, lasting clearance |
| pairLock | 456,464,470,478,485,494,498 (7) | Colour-pair dependency |
| trap | 457,467,473,477,482,487,495 (7) | One fair trap (L495 rescue) |
| bossChain | 462,483,490 (3) | Peel-first; L490 worm rescue |
| bossTrap | 455,469,476,497 (4) | One fair trap; L476 open rescue |
| godPair | 451,465,486,493 (4) | Multi-pair; L451 coffee open |
| godTrap | 458,472,479,500 (4) | One trap; L479 open + L500 finale |

Decade intent (peaks and relief):

| Decade | Emphasis |
|---|---|
| 451–460 | God/boss open; L460 breather on shallow plus |
| 461–470 | Chain/detour mid; dragon bossChain |
| 471–480 | Dense specials; L476/L479 open rescues |
| 481–490 | L483 deep bossChain; L490 worm |
| 491–500 | L495 trap rescue; castle/wizard finish |

## Duration analysis (Task 3)

| Batch | Median peel | p10 | p90 | Short (&lt;11) | Median arrows |
|---|---|---|---|---|---|
| Production 451–500 | 19 | — | — | 1 (peel&lt;12: 2 normals) | 55 |
| Phase 2D candidate | 13 | 10 | 16 | ~6 | 31 |
| **Phase 2E candidate** | **13** | **11** | **17** | **5** | **31** |

Notably short candidates (peel &lt;11): L463 (8), L474 (9), L481 (10), L487 (10),
L488 (10). L463/L474/L481 are intentional breathers on peel-resistant masks.
L487/L488 meet role floors but sit at the low end — flagged for playtesting.

Strong duration keeps: **L483** peel **28→22**, **L479** **30→18**, **L462**
**30→17**, **L491** **11→14** (breather still lengthened).

## Candidate vs original by decade

| Decade | Arrows o→c | Peel o→c | Traps | Notes |
|---|---|---|---|---|
| 451–460 | 55→31 | 19→13 | 3 | L451 godPair open |
| 461–470 | 61→32 | 21→13 | 2 | Dragon bossChain |
| 471–480 | 56→33 | 24→14 | 5 | Highest trap decade; open rescues |
| 481–490 | 52→29 | 17→13 | 2 | L483 peel 22; L490 worm |
| 491–500 | 61→37 | 25→14 | 3 | L495 peel 9→12; fullest arrow decade |

Crowd **0.70→0.19**. Max nearest arrow IoU **0.22**. **15/15** traps fair.

## Boss / God findings (Task 4)

| L | Role | Peel o→c | Open o→c | Dead o→c | Traps | Notes |
|---|---|---|---|---|---|---|
| 451 | godPair | 44→17 | 18→16 | 0→0 | 0 | Multi-pair coffee |
| 455 | bossTrap | 18→13 | 25→13 | 0→0.47 | 1 | Ring |
| 458 | godTrap | 27→12 | 20→14 | 0→0.47 | 1 | |
| 462 | bossChain | 30→17 | 26→14 | 0→0 | 0 | Dragon |
| 465 | godPair | 31→14 | 17→18 | 0→0 | 0 | |
| 469 | bossTrap | 29→17 | 26→15 | 0→0.19 | 1 | |
| 472 | godTrap | 30→14 | 22→15 | 0→0.31 | 1 | |
| **476** | bossTrap | 26→15 | **33→14** | 0→0.44 | 1 | Open rescue |
| **479** | godTrap | 30→**18** | **33→11** | 0→0.25 | 1 | Strong duration |
| **483** | bossChain | 28→**22** | 24→20 | 0→0 | 0 | Best peel retention |
| 486 | godPair | 27→13 | 22→13 | 0→0 | 0 | |
| **490** | bossChain | 13→12 | 18→9 | 0→0 | 0 | Small worm mask limit |
| 493 | godPair | 37→17 | 20→14 | 0→0 | 0 | Castle |
| 497 | bossTrap | 38→16 | 24→10 | 0→0.41 | 1 | |
| **500** | godTrap | 44→16 | 16→14 | 0→0.31 | 1 | Wizard finale |

Specials remain at ~8–11 dp (masks unchanged). Crowding falls sharply.
Preceding chains/detours/pairLocks prepare specials without copying 2D IDs.

## Density, variety, duplicates (Tasks 5–6)

- Crowding typically falls from ~0.7 to ~0.1–0.4.
- Max nearest arrow IoU **0.22**; no exact fingerprint duplicates in audit.
- Peel-resistant normals honestly assigned as breathers rather than forced into
  failing deep-chain briefs.
- Contact sheets: clearer corridors; silhouettes retained; specials less “texture”.

## Validation (Tasks 7–8)

`flutter test test/candidates/phase2e_test.dart`: **9 of 9 passed.**

Also: `dart format` + `dart analyze` clean;
`flutter test --exclude-tags generator,campaign,slow,release,candidates`: **206 passed**.

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels **1–450** and **501–1000** byte-identical to production.
- Levels **451–500** differ; Phase 1 / 1B / 2A–2D baselines still present.
- Duration guards: median peel ≥13, arrows ≥31, short ≤8.
- Strict audit: 1000 valid/solvable, 0 unverified, 0 fallback, 0 duplicates.
- Stored solution + DFS replay in `GameState` for every changed level.
- All 15 traps `TrapFairness.ok`; non-trap roles dead-end rate 0 where required.
- Targeted: L490 peel ≥10; L495 peel &gt; production; L476/L479 openings tighter.
- Determinism for 451, 490, 500.
- `assets/levels.bin` SHA-1: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

### Search limits

Reachability cap **200,000**. **14 specials** incomplete:
451, 455, 458, 462, 465, 469, 472, 476, 479, 483, 486, 493, 497, 500.
(L490 worm completed under the cap.) Traps on incomplete boards were still
proven via constructive solution path + `GameState` deadlock. Other dead ends
there are **unverified**, not “none”.

## Visual checks (Task 6 / 9)

- Viewport **366×600**, harness (not a device).
- Light: original + candidate for representatives and all specials.
- Dark: candidate specials (`sheet_specials_dark.png`).
- Arabic RTL: **not** screenshot-tested.
- Real-device testing: **not** performed.

## Evaluation (Task 10)

| Question | Observation |
|---|---|
| More varied structures? | Yes — 9 roles, schedule ≠ 2D |
| Meaningful decisions? | 15 fair traps + pair/chain/detour mix |
| Peel duration vs production? | Still shorter (13 vs ~19); better p10/p90 than 2D |
| Readability without over-thinning? | Crowd 0.70→0.19; arrows match 2D median |
| Distinctive specials? | L483 peel 22; L479 open rescue; L500 trap finale |
| Avoid prior patterns? | Salt 66; different IDs; more honest breathers |
| Over-reliance on heuristics? | Median alone flat vs 2D — distribution + specials matter |

Do **not** claim improved enjoyment, retention, or engagement without players.

## Trade-offs

- Median peel still well below production size-driven specials; reverse
  construction + crowding caps bind duration.
- Nine breathers (vs 2D’s seven) — some exist because deep roles failed on those
  masks; documented as intentional, not hidden.
- L490 worm cannot reach deep boss peels on its small mask (**13→12** modest).
- Incomplete reachability on 14 specials limits exhaustive deadlock claims.

## Files changed

- `test/candidates/phase2e.dart` (new)
- `test/candidates/phase2e_test.dart` (new)
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE2E.md` (this report)

Artifacts: `build/candidates/phase2e_451_500/`.
Full per-level tables: `candidates.json`.
