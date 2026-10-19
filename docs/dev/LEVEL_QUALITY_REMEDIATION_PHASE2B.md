# Level quality remediation, phase 2B (levels 301–350)

Status: **development candidate only.** Follow-on to
[LEVEL_QUALITY_REMEDIATION_PHASE2A.md](LEVEL_QUALITY_REMEDIATION_PHASE2A.md).
Uses the **production** campaign as baseline (not the Phase 2A binary).
`assets/levels.bin` was not modified. Phase 1 / 1B / 2A artifacts were left
in place.

## Reproducing

```bash
flutter test test/candidates/phase2b_test.dart
```

Output under `build/candidates/phase2b_301_350/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate (production + 301–350) |
| `candidates.json` | Per-level roles, profiles, trap fairness, silhouette |
| `boards.txt` | ASCII boards |
| `campaign_audit.json` | Strict audit |
| `snapshots/original`, `candidate` | Phone 366×600 light (+ dark for candidates) |
| `sheet_representative.png`, `sheet_specials.png`, `sheet_specials_dark.png` | Contact sheets |

Code: `test/candidates/phase2b.dart`, `phase2b_test.dart`.

## Original baseline (Task 1)

From `build/level_quality.json`:

| Band | Type | n | Median arrows | Peel | Dead-end | Cell dp | Crowd |
|---|---|---|---|---|---|---|---|
| 251–300 | normal | 36 | 49 | 17 | 0.00 | 16.5 | 0.73 |
| **301–350** | **normal** | **35** | **50** | **16** | **0.00** | **16.5** | **0.72** |
| 351–400 | normal | 36 | 49 | 18 | 0.00 | 16.5 | 0.73 |
| 301–350 | boss | 8 | 124 | 31 | 0.00 | 8.7 | 0.85 |
| 301–350 | god | 7 | 97 | 27 | 0.00 | 8.7 | 0.71 |

Confirmed issues in production 301–350:

- Plateau continues: normals match 251–300 (~50 arrows, peel ~16, dead 0).
- Almost no order deadlocks in random play (L330 is a rare exception at 0.75).
- **L301 boss** is shallow vs its role: peel **13**, opening **34**, crowd 0.87.
- Specials remain size-driven (91–174 arrows) with crowding 0.62–0.89 at ~8–10 dp.

Exact vs estimate: peel/opening/fill are exact under the exit rule; dead-end
rate is a 32-playout estimate; exhaustive dead-end absence is only proven when
reachability completes.

## Design vs Phase 2A (Tasks 2–4, 9)

| Principle | Phase 2A | Phase 2B |
|---|---|---|
| Role mix | Mostly trap or breather | **chain / pairLock / trap / breather** + boss/god variants |
| Trap count (batch) | 49 | **28** |
| Median peel (candidate) | 10 | **12** |
| Median dead-end rate | 0.34 | **0.19** |
| Dead-end scoring | Chase ~0.35 | Mild guide only; ceiling by role |
| Seed salt | 22 | **33** |
| Breathers | 8 (254…300) | **7** (305,312,320,328,335,342,349) |
| God default | Often 2 traps | **1 trap** + either heavy detours or pairs |

Reusable from 2A: reverse construction, outline bias, `TrapFairness` with
constructive solution-path fallback, byte-identical outside the edit range.

Deliberately avoided: trap-majority normals, chasing high dead-end rates,
short peel floors that made boards feel abrupt.

### Role schedule

| Role | Levels (count) | Intent |
|---|---|---|
| breather | 305,312,320,328,335,342,349 (7) | Order-independent relief |
| chain | 302,307,310,316,321,327,334,341,345,348 (10) | Deep peel, detours, **no traps** |
| pairLock | 303,309,314,319,324,331,338,344 (8) | Colour pairs as the main dependency |
| trap | 306,313,317,323,326,330,333,337,340,347 (10) | One fair live trap |
| bossChain | 301,315,329,343 (4) | Peel-first bosses; L301 rescue |
| bossTrap | 308,322,336,350 (4) | 1–2 traps |
| godTrap | 304,325,339 (3) | One trap + dense deflectors |
| godPair | 311,318,332,346 (4) | Heavy pairs + one trap |

## Candidate vs original by decade

| Decade | Arrows o→c | Peel o→c | Dead o→c | Traps | Role mix |
|---|---|---|---|---|---|
| 301–310 | 58→30 | 16→12 | 0→0.00* | 4 | chain-heavy start |
| 311–320 | 51→28 | 18→12 | 0→0.25 | 5 | godPair + breathers |
| 321–330 | 51→30 | 16→13 | 0→0.34 | 7 | more traps mid-band |
| 331–340 | 56→30 | 21→11 | 0→0.28 | 7 | mixed |
| 341–350 | 52→30 | 23→12 | 0→0.00* | 5 | chain/breather finish |

\*Decade median can be 0 when half the levels are chain/breather/pairLock.

Batch medians: peel **12** (vs production ~18 mixed, vs 2A **10**); dead-end
**0.19** (vs 2A **0.34**); **28/28** traps fair.

## Boss / God findings (Task 3)

| L | Role | Shape | Peel o→c | Open o→c | Dead o→c | Traps |
|---|---|---|---|---|---|---|
| **301** | bossChain | dinosaur | **13→16** | 34→16 | 0→0.34 | 1 |
| 308 | bossTrap | sneaker | 23→15 | 20→9 | 0→0.41 | 1 |
| 315 | bossChain | dodo | 31→14 | 31→15 | 0→0.44 | 1 |
| 322 | bossTrap | phoenix | 27→17 | 25→18 | 0→0.47 | 2 |
| 329 | bossChain | bear | 39→23 | 41→14 | 0→0.50 | 1 |
| 336 | bossTrap | cupcake | 43→14 | 13→12 | 0→0.31 | 2 |
| 343 | bossChain | joystick | 32→17 | 22→15 | 0→0.25 | 1 |
| 350 | bossTrap | ship | 29→17 | 24→9 | 0→0.28 | 2 |
| 304 | godTrap | cat | 38→19 | 15→10 | 0→0.47 | 1 |
| 311 | godPair | genie | 20→11 | 25→16 | 0→0.25 | 1 |
| 318 | godPair | cloud | 27→10 | 12→11 | 0→0.31 | 1 |
| 325 | godTrap | peacock | 37→15 | 17→13 | 0→0.38 | 1 |
| 332 | godPair | palmTree | 19→14 | 19→17 | 0→0.50 | 1 |
| 339 | godTrap | dove | 28→14 | 32→17 | 0→0.34 | 1 |
| 346 | godPair | jellyfish | 23→13 | 21→18 | 0→0.25 | 1 |

L301 now peels deeper than production. Specials still sit at ~8–10 dp (masks
unchanged); crowding is lower. Silhouettes remain hard to name at phone size;
lower density helps structure more than identity.

## Density, variety, duplicates (Task 5)

- Crowding typically falls from ~0.7+ to ~0.1–0.4.
- Max nearest arrow IoU **0.19**; no exact fingerprint duplicates in audit.
- Chain and pairLock levels provide distinct solving structures from traps.
- Useful shape recurrence kept via preserved `maskShape` / schedule.

## Validation (Tasks 6–7)

`flutter test test/candidates/phase2b_test.dart`: **9 of 9 passed.**

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels **1–300** and **351–1000** byte-identical to production.
- Levels **301–350** differ; baselines for Phase 1 / 1B / 2A still present and different.
- Role-mix test: non-trap roles ≥ trap roles.
- Strict audit: 1000 valid/solvable, 0 unverified, 0 fallback, 0 duplicates.
- Stored solution + DFS replay in `GameState` for every changed level.
- All 28 traps `TrapFairness.ok`; non-trap roles dead-end rate 0 (where required).
- Determinism for 301, 320, 346.
- `assets/levels.bin` SHA-1: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

### Search limits

Reachability cap **200,000**. **14 specials** incomplete:
301, 308, 311, 315, 318, 322, 325, 329, 332, 336, 339, 343, 346, 350.
Traps on those boards were still proven via constructive solution path +
`GameState` deadlock. Other dead ends there are **unverified**, not “none”.

## Visual checks (Task 8)

- Viewport **366×600**, harness (not a device).
- Light: original + candidate for representative specials and normals.
- Dark: candidate specials sample (`sheet_specials_dark.png`).
- Arabic RTL: not screenshot-tested; board is grid-centred / not locale-driven.

## Evaluation vs Phase 2A (Task 9)

| Metric | Production 301–350 (normals) | Phase 2A batch | Phase 2B batch |
|---|---|---|---|
| Decision variety | Low (dead≈0) | Trap-heavy | **Roles diversified** |
| Median peel | ~16–18 | 10 | **12** |
| Median dead-end | 0 | 0.34 | **0.19** |
| Trap count | ~0 live | 49 | **28** |
| Readability | Dense/crowded | Improved | Improved, slightly fuller than 2A |

Improvements that do **not** depend on a single metric: more role types,
higher peel than 2A while keeping live fair traps, L301 rescue, fewer
repetitive trap boards.

Remaining questions for playtesting: whether chain levels feel distinct from
traps in the hand; whether peel 11–15 feels long enough after production’s
longer peels; special readability at 8 dp; whether to combine 2A+2B later.

## Files changed

- `test/candidates/phase2b.dart` (new)
- `test/candidates/phase2b_test.dart` (new)
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE2B.md` (this report)

Artifacts: `build/candidates/phase2b_301_350/`.
Full per-level tables: `candidates.json`.
