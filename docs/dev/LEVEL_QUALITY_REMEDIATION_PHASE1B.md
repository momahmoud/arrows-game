# Level quality remediation, phase 1B (levels 4–24)

Status: **development candidate only.** Refines the Phase 1 candidates.
`assets/levels.bin` was not modified. The Phase 1 baseline under
`build/candidates/early_phase1/` was left in place. Whether to replace
production levels remains a separate decision after player testing.

Follow-ups: [LEVEL_QUALITY_REMEDIATION_PHASE1.md](LEVEL_QUALITY_REMEDIATION_PHASE1.md),
[LEVEL_QUALITY_AUDIT.md](LEVEL_QUALITY_AUDIT.md).

## Reproducing

```bash
flutter test test/candidates/early_phase1b_test.dart
# or, with Phase 1 as well:
flutter test --tags candidates
```

Output (gitignored) under `build/candidates/early_phase1b/`:

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level Phase 1B candidate campaign |
| `candidates.json` | Per level: intent, seed, traps/fairness, original + Phase 1 + 1B profiles, silhouette |
| `boards.txt` | ASCII boards |
| `campaign_audit.json` | Strict audit of the Phase 1B campaign |
| `snapshots/original`, `phase1`, `phase1b` | Phone 366×600 renders (1B includes light and dark) |
| `sheet_specials_triple.png` | Original / Phase 1 / Phase 1B for L10,14,17,21,24,12 |
| `sheet_*_orig_vs_1b.png` | Original vs Phase 1B for 4–24 |
| `sheet_specials_dark.png` | Phase 1B specials in dark theme |

Code: `test/candidates/early_phase1b.dart`, `early_phase1b_test.dart`,
`silhouette_metrics.dart`, plus outline bias in `candidate_builder.dart`.
Phase 1 files are unchanged in behaviour when `outlineBias` is 0 (default).

## What changed vs Phase 1

1. **Outline/tip-biased placement.** The builder prefers mask outline cells and
   tip cells (outline with ≤2 mask neighbours: ears, fins, fingers, limbs).
   Bias fades after ~55–78% of the fill target so interiors still reach the
   Phase 1 fill floor.
2. **Silhouette-aware selection.** Among layouts that meet the Phase 1 brief,
   specials are ranked by outline cover and tip cover, not fill alone.
3. **Trap fairness filter.** Every trap must be a live decision with at least
   one competing free move at that state, and wrong-tapping the waste arrow
   must deadlock in the real `GameState` with both facing arrows left.
4. **First trap (L12).** Decision after 2–6 taps, competing free moves ≥ 1,
   dead-end estimate targeted near 0.28.
5. **New seed salt (11)** and more seeds on specials (512) so Phase 1B explores
   a different deterministic family without overwriting Phase 1.

## Silhouette findings (Task 2)

Measured outline/tip cover on production, Phase 1, and Phase 1B (phone
viewport inspection of light renders):

| Level | Shape | Outline o/p1/p1b | Tips o/p1/p1b | Visual note (light, harness) |
|---|---|---|---|---|
| 7 | peaceHand | 1.00 / 0.84 / **0.87** | 1.00 / 0.71 / **0.93** | Still the clearest special; fingers read |
| 10 | mermaid | 1.00 / 0.77 / **0.79** | 1.00 / 0.75 / **0.82** | Still abstract at 12.7 dp; tip cover up, not “obvious mermaid” |
| 14 | seaTurtle | 1.00 / 0.76 / **0.82** | 1.00 / 0.63 / **0.73** | Outline denser than Phase 1; shape still organic |
| 17 | unicorn | 1.00 / 0.75 / **0.83** | 1.00 / 0.60 / **0.78** | Head/neck mass clearer than Phase 1 |
| 21 | catFace | 1.00 / 0.75 / **0.85** | 1.00 / 0.43 / **0.68** | Ears much better occupied; face still readable |
| 24 | lion | 1.00 / 0.65 / **0.83** | 1.00 / 0.50 / **0.76** | Strongest tip/outline gain; still reads as a rounded mane blob at phone size |

Production outline/tip cover is ~1.0 because the boards are almost fully
filled; that does not make the animal readable at 11.8–13.7 dp. Phase 1B
improves **feature occupation** relative to Phase 1 without returning to
production density. Mermaid and lion remain hard to name at a glance; that
limit is mostly cell size and mask geometry, not missing tips alone.

## Trap fairness review (Task 3)

All Phase 1B traps are live, reachable, and confirmed against `GameState`
(`wrongTapDeadlocks`, facing pair stranded). None of the waste arrows is free
on the opening board.

| L | Waste | Taps to decision | Free at decision | Competing free | Dead rate (p1→1b) | Fairness note |
|---|---|---|---|---|---|---|
| **12** | a_12_0 | 3 | 8 | **7** | 0.38→**0.28** | First trap: short peel, many alternatives; waste not free at start |
| 14 | a_14_0 | 12 | 9 | 8 | 0.34→0.19 | Decision deeper; still has competing moves |
| 16 | a_16_0 | 6 | 7 | 6 | 0.47→0.41 | Mid-depth |
| 17 | a_17_0 | 1 | 9 | 8 | 0.31→0.34 | Early decision with many alternatives (readable risk) |
| 18 | a_18_0 | 2 | 5 | 4 | 0.34→0.44 | Early; dead-end estimate rose (heuristic) |
| 20 | a_20_0 | 5 | 6 | 5 | 0.25→0.47 | Estimate up; still competing moves |
| 21 | a_21_0 / a_21_3 | 2 / 3 | 10 / 12 | 9 / 11 | 0.50→0.50 | Both traps early; search for other dead ends hit cap |
| 22 | a_22_0 | 9 | 7 | 6 | 0.38→0.28 | Mid-late decision |
| 24 | a_24_0 / a_24_3 | 5 / 5 | 9 / 10 | 8 / 9 | 0.50→0.41 | Both mid-depth; 3 exhaustive dead states |

Dead-end rate remains a random-play heuristic, not player frustration.
Order-independent levels (no traps) still show 0 dead ends where the search
finished.

## Per-level comparison table

`o` = production, `p1` = Phase 1, `1b` = Phase 1B. Cell dp matches production
on original masks (scaled masks on 4–6, 8 enlarge cells as in Phase 1).

| L | Type | Arrows o/p1/1b | Fill o/p1/1b | Crowd o/p1/1b | Open o/p1/1b | Peel o/p1/1b | Dead p1/1b | Why refined |
|---|---|---|---|---|---|---|---|---|
| 4 | normal | 26/7/7 | .90/.71/.71 | .69/0/0 | 10/3/3 | 7/4/3 | 0/0 | Outline bias on intro board |
| 5 | normal | 26/7/9 | .91/.72/.77 | .69/0/.22 | 9/2/3 | 12/5/5 | 0/0 | Slightly fuller silhouette |
| 6 | normal | 26/10/10 | .95/.71/.71 | .77/0/.20 | 5/3/3 | 11/6/6 | 0/0 | Same role (first pair) |
| 7 | boss | 52/27/25 | .89/.82/.82 | .71/.07/.08 | 15/7/7 | 11/11/11 | 0/0 | Tip cover 0.71→0.93 |
| 8 | normal | 29/10/11 | .91/.72/.74 | .69/.20/0 | 7/3/3 | 15/5/5 | 0/0 | Breather |
| 9 | normal | 26/14/15 | .97/.78/.77 | .77/.14/0 | 8/3/3 | 11/9/7 | 0/0 | Outline preference |
| 10 | god | 48/28/30 | .92/.80/.79 | .58/.14/.17 | 17/6/6 | 5/9/11 | 0/0 | Tip/outline ↑; still abstract |
| 11 | normal | 26/14/12 | .94/.79/.78 | .62/.14/.17 | 11/4/5 | 9/5/6 | 0/0 | Breather |
| 12 | normal | 26/15/15 | .93/.79/.80 | .81/.20/.33 | 8/3/4 | 7/5/5 | .38/.28 | Fairer first trap |
| 13 | normal | 26/19/15 | .89/.82/.81 | .77/.10/.13 | 9/3/3 | 11/8/9 | 0/0 | Depth, no traps |
| 14 | boss | 68/40/31 | .90/.80/.81 | .68/.23/.23 | 15/7/5 | 17/11/11 | .34/.19 | Outline ↑; fewer arrows |
| 15 | normal | 26/14/13 | .92/.82/.81 | .50/0/0 | 14/3/3 | 6/6/6 | 0/0 | Breather |
| 16 | normal | 26/16/15 | .87/.82/.80 | .69/.19/.33 | 3/3/3 | 12/7/7 | .47/.41 | Fair trap retained |
| 17 | god | 84/36/38 | .92/.81/.79 | .76/.17/.16 | 19/7/7 | 14/11/10 | .31/.34 | Tip cover 0.60→0.78 |
| 18 | normal | 26/16/16 | .89/.80/.76 | .85/.19/.19 | 9/3/3 | 7/9/7 | .34/.44 | Fair trap; estimate ↑ |
| 19 | normal | 26/12/14 | .90/.81/.82 | .54/.17/.14 | 9/4/5 | 10/7/7 | 0/0 | Breather |
| 20 | normal | 29/20/19 | .90/.81/.81 | .79/.25/.16 | 3/2/4 | 15/11/8 | .25/.47 | Fair trap; estimate ↑ |
| 21 | boss | 81/40/40 | .92/.78/.78 | .74/.25/.35 | 25/5/7 | 14/11/10 | .50/.50 | Tips 0.43→0.68 (ears) |
| 22 | normal | 38/22/24 | .89/.81/.81 | .68/.32/.42 | 11/4/4 | 14/9/9 | .38/.28 | Fair trap |
| 23 | normal | 35/18/20 | .92/.76/.77 | .74/.11/.10 | 14/4/5 | 9/7/7 | 0/0 | Breather |
| 24 | god | 94/45/45 | .89/.77/.79 | .82/.29/.18 | 26/7/5 | 15/10/12 | .50/.41 | Outline 0.65→0.83 |

## Validation (actual results)

`flutter test test/candidates/early_phase1b_test.dart`: **8 of 8 passed.**

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels 1–3 and 25–1000 byte-identical to production.
- Phase 1 `levels_candidate.bin` still present and **not equal** to Phase 1B.
- Strict audit: 1000 valid, 1000 confirmed solvable, 0 unverified, 0 fallback,
  0 duplicate fingerprints, no blockers; all changed levels
  `storedSolutionValid`.
- Stored solution and independent DFS replay in `GameState` for every changed
  level.
- Every trap fair and deadlocking as above; non-trap levels dead-end rate 0.
- Nearest arrow IoU &lt; 0.5; fingerprints unique vs originals and within campaign.
- Determinism for levels 4, 12, 21.
- `assets/levels.bin` SHA-1 still `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

## Visual checks actually completed

- Phone viewport **366×600**, harness renders (not a physical device).
- **Light** theme: original, Phase 1, and Phase 1B for levels 4–24.
- **Dark** theme: Phase 1B for levels 4–24 (specials sampled in
  `sheet_specials_dark.png`).
- **RTL / localization:** board layout is grid-centred and not driven by
  locale; no separate Arabic/RTL screenshot pass was run for these candidates.
  Do not treat this as device or locale QA.

## Limits and trade-offs

- Cell size on specials is unchanged (shapes kept); mermaid/lion recognition at
  phone size remains limited.
- L21 exhaustive search still hits the 400k cap; traps are proven by game
  replay, other dead ends are not exhaustively ruled out.
- Dead-end rates are random-play estimates (L18/L20 rose vs Phase 1 while traps
  stayed fair).
- Boards remain seeded-search products, not hand-drawn.
- No claim of greater enjoyment without player testing.

## Files changed (tooling / docs only)

- `test/candidates/candidate_builder.dart` — `outlineBias`, tip/outline scoring
- `test/candidates/silhouette_metrics.dart` — new
- `test/candidates/early_phase1b.dart` — new
- `test/candidates/early_phase1b_test.dart` — new
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE1B.md` — this report

Phase 1 baseline artifacts under `build/candidates/early_phase1/` were not
replaced. Production `assets/levels.bin` was not written.
