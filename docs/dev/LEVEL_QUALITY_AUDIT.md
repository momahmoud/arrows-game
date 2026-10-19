# Level quality audit (packaged campaign)

Audit of the 1,000 levels in `assets/levels.bin` (sha256
`d0604862…6626`, unchanged). No level content was modified. Metrics are
candidate signals for review, not verdicts; "objective" sections report
measurements, "recommendations" sections are design judgement.

## Reproduce

```bash
LEVEL_QUALITY_JSON=build/level_quality.json flutter test test/level_quality_test.dart
# Board renders for manual review (real Flame components, 366×600 phone):
BOARD_SNAPSHOT_DIR=build/quality BOARD_SNAPSHOT_VIEWPORTS=phone \
  BOARD_SNAPSHOT_THEMES=light BOARD_SNAPSHOT_LEVELS=1,4,7,10,402,570 \
  flutter test test/visual/board_snapshot_test.dart --plain-name renders
```

The JSON holds one record per level plus every section summarized below.
Output is deterministic (two runs produce byte-identical JSON). CI runs the
same test in the `campaign` step and uploads `level_quality.json`.

Code: `lib/data/level_generator/level_quality.dart` (per-level profile,
similarity), `lib/data/level_generator/campaign_quality_report.dart`
(campaign sections, thresholds in `QualityThresholds`).

## Rules the metrics use

Taken from `GameState._computeExitInfo` (same rule as `LevelSolver` and
`CampaignAudit`): a tapped arrow leaves when the ray from its head reaches the
board edge; its own body and its color partner never block; directional dots
turn the ray and are consumed; neutral dots are consumed. A color pair is one
tap. `SnakeMechanic` is visual only.

Consequence: **without directional dots, removing an arrow can only free
cells, so every sequence of legal taps solves the level** (no dead ends).
Order only matters through dot consumption. The test suite confirms the
profiler against `GameState` (opening legal moves and full replays on 57
sampled levels, and every dead end found).

## Metrics

| Metric | Meaning | Approximation |
|---|---|---|
| `units` | tap targets (arrows, pairs counted once) | – |
| `openingShare` | share of units free on the first tap | exact |
| `peelRounds`, `peelProfile` | rounds when all free units are removed each round = length of the longest blocking chain | exact for dot-free levels; with dots, one valid order |
| `trapRate` | mean share of remaining units that are blocked, over 32 seeded random legal playouts = chance an uninformed tap costs a life | players inspect before tapping; measures how much inspection a board demands |
| `forcedShare` | share of steps with exactly one legal tap | same playouts |
| `meanLegalMoves` | legal taps per step | same playouts |
| `deadEndRate` | share of random *legal* playouts that end in a deadlock | 32 samples; 0 does not prove no dead end exists on dot levels |
| `maxFanIn` | most units first-blocked by one unit | opening state only |
| `meanBlockerDistance`, `hiddenBlockerShare` | distance from a blocked head to its blocker; share 6+ cells away | perceptual proxy |
| `cellDp` | cell size in logical px at 1× zoom on a 366×600 play area, via the renderer's `BoardLayout` | play area varies by device; pinch zoom to 4× exists |
| `headCrowding`, `adjacencyShare` | heads with another head in the 8 neighbours; arrow cells touching another arrow | clutter proxy |
| `silhouette` | mask outline hash, identical under rotation/mirroring | – |
| `LevelSimilarity` | IoU of masks, directed arrow cells (cell + link toward head) and heads under the best of 8 symmetries | geometric, not solution-based |

Arrow count is reported but never used alone as difficulty.

## 1. Structural and solvability results (objective)

`CampaignAudit` (strict): 1000/1000 structurally valid, 1000 confirmed
solvable, 0 unverified, 0 confirmed unsolvable, 0 exact duplicates, 0
fallback. Solver timeouts are reported as unverified, never unsolvable.

## 2. Difficulty curve (objective)

Medians per range and type:

| Range | Type | n | Labels | Units | Peel rounds | Trap rate | Opening share | Forced | Cell px |
|---|---|---|---|---|---|---|---|---|---|
| 1-20 | normal | 13 | easy | 26 | 11 | 0.69 | 0.35 | 0.14 | 25.3 |
| 1-20 | boss | 2 | hard | 68 | 17 | 0.79 | 0.29 | 0.06 | 19.4 |
| 1-20 | god | 2 | legend | 81 | 14 | 0.77 | 0.35 | 0.04 | 12.7 |
| 21-50 | normal | 21 | medium | 31 | 12 | 0.73 | 0.30 | 0.12 | 20.6 |
| 21-50 | boss | 5 | expert | 73 | 17 | 0.77 | 0.29 | 0.06 | 11.8 |
| 21-50 | god | 4 | legend | 91 | 25 | 0.81 | 0.29 | 0.09 | 12.7 |
| 51-100 | normal | 36 | hard | 34 | 13 | 0.74 | 0.29 | 0.17 | 19.4 |
| 51-100 | boss | 7 | master | 108 | 21 | 0.81 | 0.25 | 0.06 | 10.6 |
| 51-100 | god | 7 | legend | 103 | 25 | 0.83 | 0.22 | 0.07 | 11.4 |
| 101-250 | normal | 107 | expert, master | 41 | 15 | 0.76 | 0.27 | 0.16 | 17.3 |
| 101-250 | boss | 21 | legend | 88 | 25 | 0.83 | 0.25 | 0.09 | 8.7 |
| 101-250 | god | 22 | legend | 100 | 30 | 0.85 | 0.20 | 0.09 | 8.9 |
| 251-500 | normal | 178 | master, legend | 48 | 18 | 0.79 | 0.27 | 0.16 | 15.7 |
| 251-500 | boss | 36 | legend | 107 | 29 | 0.84 | 0.24 | 0.08 | 8.7 |
| 251-500 | god | 36 | legend | 105 | 29 | 0.85 | 0.23 | 0.09 | 8.7 |
| 501-750 | normal | 179 | legend | 52 | 18 | 0.79 | 0.27 | 0.13 | 15.0 |
| 501-750 | boss | 36 | legend | 106 | 28 | 0.84 | 0.23 | 0.08 | 8.2 |
| 501-750 | god | 35 | legend | 101 | 30 | 0.85 | 0.21 | 0.10 | 8.7 |
| 751-1000 | normal | 179 | legend | 57 | 20 | 0.80 | 0.27 | 0.13 | 14.3 |
| 751-1000 | boss | 35 | legend | 107 | 28 | 0.84 | 0.23 | 0.08 | 8.7 |
| 751-1000 | god | 36 | legend | 100 | 29 | 0.85 | 0.22 | 0.10 | 8.7 |

Findings:

- **Tutorial to level 4 jump.** Tutorials have 2–3 units; level 4 has 26
  (7 peel rounds). Rendered, level 4 is clean and readable at 36.6 px, so the
  jump is in size more than clarity.
- **Directional dots are introduced once and then disappear.** Tutorial 3
  shows one dot; no level has a directional dot again until boss 21
  (11 dots, 79 units), then normal 22 (6 dots). Pairs ramp gently (tutorial 2,
  then 1 pair from level 16).
- **Special levels form a sawtooth.** 155 play-order steps more than double
  the unit count (every boss/god against the level before), e.g. 16→17
  (25→81 units), 44→45 (32→95), 48→49 (30→72).
- **Normal levels plateau after ~250.** From 251 to 1000 median peel rounds
  go 18→20, trap rate 0.79→0.80, opening share stays 0.27; only units grow
  (48→57). Relational structure (opening share ≈0.27, forced ≈0.13–0.16) is
  flat from level 101 to 1000.
- **Boss and god levels plateau after ~100** at ~100–107 units, ~28–30 peel
  rounds, trap 0.84–0.85, and 8.2–8.9 px cells through level 1000.
- **Local outliers among normal levels** (robust z ≥ 3 vs ±10 neighbours):
  - Much deeper chains: 279 (37 rounds vs local 16), 494 (30 vs 16), 173
    (27 vs 14), 317 (29 vs 16), 153 (25 vs 15).
  - Much shallower: 50 (6 vs 13), 131 (9 vs 15), 40 (8 vs 13).
  - Unusually forgiving (low trap rate): 50, 40, 940, 352, 631.
  - Long single-track stretches: 317 (52% forced steps vs 13%), 279 (58%),
    916, 494, 900.

## 3. The 699 `legend` labels (objective)

`LevelGeneratorV2._difficultyFor` assigns labels from level number and type
only: normal > 400, boss > 100 (first: 105), and **every god level including
level 10**. That produces exactly 429 + 128 + 142 = 699. The label is a
schedule band, not a measurement.

Spearman correlation over normal levels: label vs level number 0.88; label vs
units 0.82 (the generator scales size with level); label vs peel rounds 0.41,
vs trap rate 0.38, vs opening share −0.14, vs dead-end rate 0.02. 37
`legend` normal levels are at or below the median `hard` level on both peel
rounds (13) and trap rate (0.74): 414, 431, 447, 460, 473, 491, 492, 495, 502,
505, 515, 530, 541, 545, 566, 573, 580, 596, 600, 671, 677, 690, 695, 697, 718,
722, 726, 732, 761, 768, 772, 856, 863, 879, 890, 940, 957.

Conclusion: not a classification bug; a broad generator category. The label
carries no information within levels 401–1000. Labels were not changed.

## 4. Puzzle depth and decisions (objective, then interpretation)

- 974 of 1,000 levels contain directional dots, but **only 31 levels showed any dead
  end** in 32 random legal playouts: 42, 70, 84, 97, 136, 158, 171, 203, 230,
  239, 330, 364, 410, 415, 427, 434, 438, 570, 612, 689, 738, 743, 773, 810,
  843, 851, 899, 909, 915, 945, 947. All were confirmed as real deadlocks in
  `GameState`. Highest rates: 427 (91%), 239 (84%), 330 (75%), 364 (72%),
  851 (66%), 203 (63%). In 10 of them (97, 171, 230, 239, 330, 364, 434, 570,
  743, 851) even "remove everything free" stalls.
- In the other 969, any legal tap is safe. The challenge there is
  finding a free arrow (trap rate 0.69–0.85: most of the board is blocked at
  any moment), not planning an order.
- Single-track candidates (≥30% forced steps): 63 levels, e.g. 33, 43, 47,
  71, 90, 95, 279, 317, 900, 916.
- Shallow/open candidates (≤6 peel rounds or ≥40% free at start): 10, 15,
  50, 97, 290, 434; 11, 15, 23, 26, 39, 40, 136, 268, 278, 284, 286, 292, 323,
  390, 411, 502, 509, 561, 571, 574, 631, 705, 890, 991.
- The 21 normal-level compositions (`straightLanes`, `interlock`,
  `multiDependency`, …) differ in path shape (turns per arrow 1.5–2.2) but
  barely in structure: median peel rounds 16–20.5, trap rate 0.77–0.80,
  opening share 0.25–0.29 across all of them (levels > 100).

Interpretation: the campaign is mostly a *search* puzzle (spot the free
arrow) with rare, unannounced *ordering* puzzles. Dead ends are the only
place where an earlier choice changes what is possible later.

## 5. Near-duplicates (objective)

- The 58 `CampaignAudit` clusters group levels with the same shape name, grid
  size and arrow count. Under the geometric similarity, **no pair exceeds a
  directed-arrow IoU of 0.23**. Across all 13,551 same-shape pairs in the
  campaign the maximum is 0.28 (median 0.14), excluding tutorials 1/2 (0.5).
  No arrangement is reused.
- What repeats is the **silhouette**: 30 of the 58 clusters have identical
  outlines in every pair (32 with mask IoU ≥ 0.95). Campaign-wide there are 328 distinct silhouettes for
  1000 levels: 672 reuses, 280 within 25 levels. Normal levels use only 20
  shape names across 713 normal levels (boss 111, god 56).
- Verdicts (`CampaignQualityReport.clusters`): 0 strong duplicates, **7
  suspicious repetitions** (identical silhouette, all members within 50
  levels): diamond 61/74/83, longRectangle 54/64/76/89, uShape 51/72/86,
  ribbon 103/111/121/131, wideRectangle 107/117/125/138, diamond
  145/163/184, plus 146/165/186. The other 51 are acceptable recurrence
  (members far apart or different outlines).
- Tightest silhouette reuse: levels 201–223 rotate five outlines with a
  period of 7 (201/208/215 staircase, 202/209/216 zShape, 204/211/218
  parallelogram, 205/212/219 cornerCluster, 207/214/221 frame), and 109/114/
  120, 762/769. The `frame` outline appears 14 times (418…981).
- Special levels never share a silhouette with a normal level; 49 boss/god
  levels share one with another special level.

## 6. Visual review (what was actually inspected)

Rendered through the real Flame components at the 366×600 phone viewport,
light theme, captured at 2× and reviewed at 1× logical size: 1, 2, 3, 4, 7,
10, 15, 40, 61, 74, 83, 201, 208, 215, 217, 239, 273, 279, 290, 317, 402, 427,
570, 707, 892, 941. Not reviewed on a device, in dark theme, or zoomed.

- Clear at 1×: tutorials, 4, 15, 40, 61/74/83, 201/208/215, 239, 279, 290,
  317 (15–37 px cells).
- 61/74/83 and 201/208/215 visibly share the same outline with different
  arrows, matching the silhouette data.
- At 8–9 px (162 levels below 9 px; 99 also with ≥75% crowded heads), heads
  are hard to tell apart without zoom. Worst seen: boss 217 (213 units) and
  god 402 (247 units, 76% one- or two-cell arrows): the dense regions read as
  texture. God 570 and boss 707 are dense mazes where colors help but heads do
  not. God 941 and boss 273 render small because their silhouettes are
  spread out with large gaps.
- Order-dependent levels (239, 427) look like any other level: nothing on
  the board signals that order matters.

Needs device and zoom review: every level in `candidates.smallCellsCrowdedHeads`,
especially 112, 122, 136, 178, 206, 210, 217, 220, 224, 402.

## 7. Special levels (objective)

- Positions match `AppConstants.levelTypeFor` (boss every 7th from 7, god
  every 7th from 10); every pattern name matches its type.
- Against the normal levels of the same 7-level cycle: 122/142 bosses and
  123/142 gods have ≥1.5× units, ~100 of each have higher trap rate, and
  101/109 deeper chains.
- Not distinct on any of those measures — bosses 273, 490, 525, 574, 588,
  630, 651, 763, 805, 819, 889, 903, 910; gods 290, 521, 563, 633, 724, 731,
  759, 822, 871, 941, 983. God 290 (31 units) is smaller than its neighbours.
- No dots or pairs: bosses 7, 14; gods 10, 395, 437 (395/437 are known
  exceptions in `verify_final_bin_test`).
- From level 251 on, boss and god medians differ by at most 7 units,
  2 peel rounds and 0.02 trap rate. Their identity is the
  silhouette and size, not a different kind of decision.

## 8. Acceptance checklist for future levels

Automated (from `CampaignAudit` and `LevelQuality`):

1. **Structural validity**: `CampaignAudit.structuralIssues` empty.
2. **Solvability**: confirmed solvable (stored solution, greedy or DFS);
   unverified blocks release.
3. **Readability**: `cellDp ≥ 9` at 1× on the reference viewport, or the
   level is explicitly marked zoom-required; `headCrowding < 0.75` when
   `cellDp < 12`; one- or two-cell arrows ≤ 50%.
4. **Depth**: for normal levels after 20, `peelRounds ≥ 7` and
   `openingShare ≤ 0.4` unless the level is an intentional breather;
   `forcedShare ≤ 0.3` unless intended.
5. **Difficulty fit**: peel rounds and trap rate within robust z ±3 of the
   surrounding ±10 normal levels, unless intentional.
6. **Variety**: no exact fingerprint duplicate; directed-arrow IoU < 0.5 with
   every same-shape level; the same silhouette not within 7 levels and not
   in more than 3 levels of any 50-level window.
7. **Special levels**: exceed the cycle's normal median on at least one of
   units ×1.5, trap rate +0.03 or peel rounds ×1.25; use dots or pairs after
   level 25.
8. **Order-dependent levels** (`deadEndRate > 0`): intentional and placed
   after the mechanic has been taught.

Needs human playtesting: whether a level is fun or satisfying, whether
silhouettes are recognizable, whether the order-dependent levels feel fair,
real tap accuracy at 8–9 px, the effect of timers on boss/god levels, and
dark-theme legibility.

## 9. Prioritized proposals (not implemented)

Each needs a separate, reviewable content change. Changing a level replaces
its board for players who have not finished it; IDs, stars and progress are
unaffected only if the level number, type and grid stay the same.

**Critical**: none found. All levels are valid and solvable, and no board was
judged unplayable at 1× with zoom available.

**High**

1. *Teach dot consumption before order-dependent levels.* Evidence: dead
   ends in 31 levels, first at boss 42, no teaching level; up to 91% of
   random legal sequences deadlock (427). Intent: a short normal level before
   42 where consuming a dot strands an arrow on purpose. Risk: changes an
   early level's content; the deadlock dialog already explains the rule.
2. *Review the highest dead-end levels for fairness:* 427, 239, 330, 364,
   851, 203. Intent: confirm by playtest that the trap is visible; otherwise
   regenerate with the same type and grid. Risk: these are also the deepest
   decisions in the campaign; do not remove order-dependence wholesale.
3. *Reduce silhouette repetition among normal levels.* Evidence: 20 shape
   names for 713 normals; five outlines on a 7-level period in 201–223; the 7
   suspicious clusters. Intent: widen the normal shape pool or vary mask
   scale/aspect per level. Risk: mask changes alter boards; shape-name rules
   must stay respected ("don't touch the special shapes" applies to
   boss/god).

**Medium**

4. *Smooth the reintroduction of directional dots*: tutorial 3 → boss 21 with
   11 dots. Intent: 1–2 dots in normal levels 11–20. Risk: low.
5. *Give boss and god distinct roles after level 100* (e.g. bosses
   order-dependent, gods deeper chains) instead of the same size band. Risk:
   design work; schedule unchanged.
6. *Specials not harder than their cycle* (13 bosses, 11 gods listed in §7):
   review, starting with god 290. Risk: low per level.
7. *Clutter at 8–9 px*: review 217, 402, 178, 210, 220, 224 on a device;
   cap one- or two-cell arrows. Risk: changes the hardest boards.
8. *Smooth the local outliers* in §2 (279, 317, 494, 173; 50, 40, 131) or
   keep them deliberately as spikes/breathers.

**Optional / long term**

9. Replace the schedule-based difficulty label with measured bands, or show
   no label for 401–1000. Risk: label is stored in the binary; changing it
   requires regeneration.
10. Add structural variety to normal compositions so they differ in
    measured structure, not only path shape.
11. Normal levels 251–1000 grow only in size; consider periodic breather
    levels and introducing more order-dependent puzzles once taught.

## Limitations

- Playout metrics are sampled (32 seeded runs); `deadEndRate = 0` on dot
  levels is not a proof that no dead end exists.
- Trap rate models uniform random taps; real players look first.
- Similarity is geometric; two different-looking boards can still play alike
  and vice versa.
- Cell size uses one reference viewport; HUD and safe areas vary by device.
- Visual review covered 26 boards at 1×, light theme, not on a device.
