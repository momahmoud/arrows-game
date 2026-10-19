# Level quality remediation, phase 1 (levels 4–24)

Status: **development candidate only.** Nothing here is shipped. `assets/levels.bin`
was not modified or regenerated, and the candidate campaign is not registered
as an asset. Whether to replace production levels 4–24 is a separate decision
that should follow player testing.

Follow-up to [LEVEL_QUALITY_AUDIT.md](LEVEL_QUALITY_AUDIT.md).

## Reproducing

```bash
flutter test --tags candidates
```

This decodes `assets/levels.bin` (read only), rebuilds levels 4–24 with fixed
seeds, splices them into an otherwise byte-identical copy of the campaign and
writes everything under `build/candidates/early_phase1/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate campaign, binary v3 |
| `candidates.json` | Per level: intent, seed, features, traps, original vs candidate profile, reachability, solver results, similarity |
| `boards.txt` | ASCII drawing of each candidate board |
| `campaign_audit.json` | Strict `CampaignAudit` report of the candidate campaign |
| `snapshots/before`, `snapshots/after` | Board renders, phone viewport 366×600, light theme |
| `sheet_04_10.png`, `sheet_11_17.png`, `sheet_18_24.png` | Before/after contact sheets |

Rendering the snapshots (the board snapshot test reads `BOARD_SNAPSHOT_BIN`
instead of `assets/levels.bin` when it is set):

```bash
BOARD_SNAPSHOT_BIN=build/candidates/early_phase1/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=build/candidates/early_phase1/snapshots/after \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light \
  BOARD_SNAPSHOT_LEVELS=4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24 \
  flutter test test/visual/board_snapshot_test.dart --plain-name renders
```

The `candidates` tag is excluded from the fast suite (CI, README and the
release checklist).

Code: `test/candidates/` (`candidate_builder.dart`, `candidate_checks.dart`,
`candidate_board.dart`, `early_phase1.dart`, `early_phase1_test.dart`). It
uses the production model, binary codec, `LevelSolver`, `CampaignAudit`,
`LevelQuality` and `GameState`. It lives under `test/` so it cannot be bundled
into the app.

## Confirmed problems in the original levels 4–24

Measured with `LevelQuality.profile` and an exhaustive reachable-state search
that uses the real exit rule:

- **Flat start.** Normal levels 4–20 all have 26 arrows (29 on 8 and 20) with
  fill 0.87–0.97. Level 4 follows a 3-arrow tutorial with 26 arrows and 10 free
  opening moves.
- **No decisions.** Every level 4–24 has a random-play dead-end rate of 0.
  Where the search finished (all normal levels except 23), it found **zero**
  dead-end states. Level 15, for example, has 272,384 reachable states and
  none of them is stuck. Any tap order wins, so the work is finding free
  arrows, not choosing an order.
- **Wide-open openings.** Normal levels start with 3–14 free moves (7 or more
  on 13 of the 15), specials with 15–26 (L24: 26 of 94 arrows).
- **Taught mechanics unused.** Tutorials 2 and 3 teach pairs and deflectors, but
  no directional dot appears until L21, and the first pair is on L16. Where
  deflectors do appear (21–24), 0–11.5% of opening exits use them.
- **Inert dots.** Each level has 4–43 neutral dots. They are consumed without
  turning a ray, so they look like a mechanic but have no effect.
- **Crowded heads.** Head crowding (share of heads touching another head) is
  0.50–0.85.
- **Specials differ mostly in size.** Bosses and gods have 48–94 arrows on
  27–28 grids. Cells are 11.8–13.7 dp on 10, 14, 17, 21 and 24 at the
  reference viewport. Their peel depth (5–17) overlaps the normal levels'
  (6–15).

## Design arc

Mechanics appear only after the tutorial that teaches them (pair: T2,
deflector: T3). "Trap" is not a new mechanic. It is an arrangement of
existing pieces: one deflector between two arrows that face each other, plus
a third arrow that can also use that deflector. Each facing arrow can only
leave through the deflector, which is consumed when used. If the third arrow
uses it first, both facing arrows are stuck and the game reports a deadlock.
Deadlock handling is unchanged (retry, home or inspect).

| Level | Type | Role |
|---|---|---|
| 4 | normal | 7 arrows, blocking only, 3 openers |
| 5 | normal | 7 arrows with bends, 2 openers |
| 6 | normal | first pair in the campaign proper |
| 7 | boss | first deflectors (3), deep peel on the big shape |
| 8 | normal | breather: 10 arrows, 2 deflectors |
| 9 | normal | deflectors plus a pair |
| 10 | god | 3 pairs and 2 deflectors |
| 11 | normal | breather |
| 12 | normal | **first trap** |
| 13 | normal | depth without traps: 2 pairs, 2 deflectors |
| 14 | boss | trap on a big shape, 3 deflectors, 1 pair |
| 15 | normal | breather |
| 16 | normal | trap and pair |
| 17 | god | trap, 3 pairs, 3 deflectors |
| 18 | normal | trap, 2 deflectors, pair |
| 19 | normal | breather |
| 20 | normal | trap, 2 pairs, 2 deflectors |
| 21 | boss | 2 traps, 6 deflectors, pair |
| 22 | normal | trap, pair, 3 deflectors |
| 23 | normal | breather: 2 pairs, 2 deflectors, no trap |
| 24 | god | 2 traps, 4 pairs, 4 deflectors |

Levels without a trap are designed to be order-independent (0 dead ends).

## Method

Levels are built backwards from the cleared board. Arrows are added one unit
at a time (a single arrow or a pair), and after every placement the board is
replayed forward with the exact exit rule. The replay matches
`GameState._computeExitInfo`: rays run to the grid edge, an arrow's own body
and its partner never block, a directional dot turns the ray and is consumed
only when the exit succeeds, and revisiting a cell blocks. A placement is kept
only if that replay clears the board. So every candidate has a stored solution
by construction, and the solution is then checked independently.

- **Kept from the original:** level number, grid size, `patternName`,
  difficulty label, `maskShape` (shape reveal and unlock), and the mask itself.
  Levels 4, 5, 6 and 8 use a centred, nearest-neighbour downscale of the
  original shape so their small arrow counts still produce large cells. All
  special shapes keep their original masks unchanged.
- **Deflectors (detours)** sit 1–3 cells in front of the arrow that uses them.
  The builder rejects layouts where another arrow consumes that dot first.
- **Traps** use the geometry described above. Each placed trap is recorded and
  must be *live*: an exhaustive breadth-first search must reach a state where
  the dot and both facing arrows are still on the board and the third arrow can
  take the dot.
- **Fill.** After the brief is met, tails grow and short gap arrows are
  inserted to reach the target fill (normal 0.8, scaled 0.7, special 0.82).
  A gap arrow must start blocked, so it never adds an opening move.
- **Selection.** Each level has 96–512 seeds. Seeds that miss the brief are
  rejected: required features, fill, unintended dead ends, head crowding above
  0.45, opening count out of band, or peel depth out of range. The remainder
  are ranked by low crowding, fill, depth and (for traps) a target dead-end
  rate near 0.35. The first seed whose traps are all live is taken.
- Seeds are `level·7919 + salt·104729 + i` with a local LCG, so the build is
  deterministic. The test rebuilds levels 4, 12 and 21 and checks that they are
  identical.

## Per-level comparison

`o→c` = original → candidate. Arrows counts include pair members.
Opening = free tap units at the start; peel = rounds of removing every free
unit. Dead = dead-end rate of random play from `LevelQuality` (an estimate).
States/dead states come from the exhaustive search (cap 400,000; "cap" means
it stopped). Similarity = highest arrow-path IoU against levels 1–100, every
level with the same shape, and the other candidates.

| L | Type | Shape, grid | Arrows | Pairs | Dir. dots | Fill | Cell dp | Crowding | Opening | Peel | Dead | States (dead) | Similarity |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | normal easy | longRectangle 15 | 26→7 | 0→0 | 0→0 | .90→.71 | 36.6→36.6 | .69→0 | 10→3 | 7→4 | 0→0 | 39,456 (0) → 27 (0) | .22 |
| 5 | normal easy | circle 16 | 26→7 | 0→0 | 0→0 | .91→.72 | 23.5→36.6 | .69→0 | 9→2 | 12→5 | 0→0 | 13,200 (0) → 14 (0) | .16 |
| 6 | normal easy | pentagon 16 | 26→10 | 0→1 | 0→0 | .95→.71 | 27.5→32.9 | .77→0 | 5→3 | 11→6 | 0→0 | 570 (0) → 38 (0) | .15 |
| 7 | boss hard | peaceHand 27 | 52→27 | 0→0 | 0→3 | .89→.82 | 19.4→19.4 | .71→.07 | 15→7 | 11→11 | 0→0 | cap → 7,896 (0) | .12 |
| 8 | normal easy | hexagon 17 | 29→10 | 0→0 | 0→2 | .91→.72 | 23.5→29.9 | .69→.20 | 7→3 | 15→5 | 0→0 | 5,284 (0) → 54 (0) | .19 |
| 9 | normal easy | octagon 18 | 26→14 | 0→1 | 0→2 | .97→.78 | 27.5→27.5 | .77→.14 | 8→3 | 11→9 | 0→0 | 4,320 (0) → 53 (0) | .19 |
| 10 | god legend | mermaid 27 | 48→28 | 0→3 | 0→2 | .92→.80 | 12.7→12.7 | .58→.14 | 17→6 | 5→9 | 0→0 | cap → 1,400 (0) | .09 |
| 11 | normal easy | diamond 19 | 26→14 | 0→0 | 0→1 | .94→.79 | 23.5→23.5 | .62→.14 | 11→4 | 9→5 | 0→0 | 41,768 (0) → 207 (0) | .27 |
| 12 | normal easy | plus 20 | 26→15 | 0→0 | 0→2 | .93→.79 | 25.3→25.3 | .81→.20 | 8→3 | 7→5 | 0→.38 | 17,800 (0) → 264 (1) | .18 |
| 13 | normal easy | uShape 20 | 26→19 | 0→2 | 0→2 | .89→.82 | 25.3→25.3 | .77→.11 | 9→3 | 11→8 | 0→0 | 6,320 (0) → 184 (0) | .17 |
| 14 | boss hard | seaTurtle 28 | 68→40 | 0→1 | 0→4 | .90→.80 | 11.8→11.8 | .68→.23 | 15→7 | 17→11 | 0→.34 | cap → 40,438 (1) | .13 |
| 15 | normal easy | cShape 22 | 26→14 | 0→0 | 0→1 | .92→.82 | 25.3→25.3 | .50→0 | 14→3 | 6→6 | 0→0 | 272,384 (0) → 156 (0) | .20 |
| 16 | normal easy | longRectangle 22 | 26→16 | 1→1 | 0→2 | .87→.82 | 36.6→36.6 | .69→.19 | 3→3 | 12→7 | 0→.47 | 1,102 (0) → 290 (1) | .19 |
| 17 | god legend | unicorn 28 | 84→36 | 3→3 | 0→4 | .92→.81 | 12.7→12.7 | .76→.17 | 19→7 | 14→11 | 0→.31 | cap → 100,584 (1) | .12 |
| 18 | normal easy | circle 23 | 26→16 | 1→1 | 0→3 | .89→.80 | 23.5→23.5 | .85→.19 | 9→3 | 7→9 | 0→.34 | 33,696 (0) → 75 (1) | .15 |
| 19 | normal easy | pentagon 24 | 26→12 | 1→0 | 0→2 | .90→.81 | 27.5→27.5 | .54→.17 | 9→4 | 10→7 | 0→0 | 7,584 (0) → 104 (0) | .16 |
| 20 | normal easy | hexagon 25 | 29→20 | 1→2 | 0→3 | .90→.81 | 23.5→23.5 | .79→.25 | 3→2 | 15→11 | 0→.25 | 848 (0) → 71 (1) | .16 |
| 21 | boss expert | catFace 28 | 81→40 | 2→1 | 11→8 | .92→.78 | 11.8→11.8 | .74→.25 | 25→5 | 14→11 | 0→.50 | cap → cap | .15 |
| 22 | normal medium | octagon 25 | 38→22 | 1→1 | 6→4 | .89→.81 | 20.6→20.6 | .68→.32 | 11→4 | 14→9 | 0→.38 | 275,648 (0) → 288 (1) | .18 |
| 23 | normal medium | diamond 25 | 35→18 | 1→2 | 5→2 | .92→.76 | 18.3→18.3 | .74→.11 | 14→4 | 9→7 | 0→0 | cap → 314 (0) | .17 |
| 24 | god legend | lion 28 | 94→45 | 3→4 | 17→6 | .89→.77 | 13.7→13.7 | .82→.29 | 26→7 | 15→10 | 0→.50 | cap → 283,932 (4) | .13 |

Neutral dots: the originals have 4–43 per level. The candidates have none,
because neutral dots have no effect on play.

`deflectedExitShare` is 0 for every candidate. The profiler measures it only
on the opening board. In the candidates, deflector arrows are placed so they
clear later in the solve, so none of them is free at the start. That their
dots are consumed by the intended arrow is checked by the builder's replay,
not by this metric.

## Traps (all verified live and deadlocking)

For every recorded trap, the test runs the exhaustive search to the decision
state. It then replays that path in the real `GameState`, taps the third
arrow (the waste), and keeps tapping whatever the game reports as free. It
requires that the game raises its deadlock callback and that both facing
arrows are still on the board.

| L | Waste arrow | Taps to the decision |
|---|---|---|
| 12 | a_12_0 | 3 |
| 14 | a_14_0 | 17 |
| 16 | a_16_0 | 5 |
| 17 | a_17_0 | 4 |
| 18 | a_18_0 | 10 |
| 20 | a_20_0 | 13 |
| 21 | a_21_0, a_21_3 | 2, 3 |
| 22 | a_22_0 | 14 |
| 24 | a_24_0, a_24_3 | 14, 19 |

An earlier L24 build placed a trap whose decision could never be reached (the
facing arrows always cleared first). This is why trap liveness is now part of
selection and validation.

## Are the specials more distinctive?

Within this arc, by the measured structure, yes:

- **Depth.** Every special peels in 9–11 rounds. Every normal level peels in
  4–9 rounds, except L20 (11).
- **Mechanics.** Specials introduce or concentrate mechanics: L7 has the first
  deflectors, L10 three pairs, L14 the first boss trap, L17 a trap with three
  pairs, L21 two traps and eight directional dots, L24 two traps and four
  pairs.
- **Opening.** Specials open with 5–7 moves, normal levels with 2–4. The
  originals overlapped heavily on both depth and opening.

They are **not** more readable at the cell level. The shapes are kept, so
cells on 10, 14, 17, 21 and 24 are still 11.8–13.7 dp. Fill dropped from
about 0.9 to about 0.8, so the silhouettes are weaker. At the reference
viewport, the lion (L24) and the mermaid (L10) read as rounded blobs rather
than recognisable animals. The peace hand (L7) and the cat face (L21) are
still identifiable.

## Validation (actual results)

`flutter test --tags candidates`: 7 of 7 tests passed.

1. Re-encoding the decoded original campaign reproduces `assets/levels.bin`
   byte-for-byte.
2. Every candidate meets its brief (feature counts and selection rules).
3. The candidate campaign has exactly 1,000 levels. Level number, grid size,
   difficulty, `maskShape` and `patternName` are unchanged for every level.
   Levels 1–3 and 25–1000 encode to identical bytes; levels 4–24 differ.
4. Strict `CampaignAudit.auditBytes` on the candidate binary:
   1,000 structurally valid, 1,000 confirmed solvable, 0 unverified, 0 confirmed
   unsolvable, 0 fallback, 0 duplicate fingerprints, no blockers. All 21 changed
   levels report `storedSolutionValid`.
5. For each changed level:
   - the stored solution replays in the audit and in `GameState`;
   - an independent DFS (`LevelSolver`, 400k states) solves the level, and that
     solution also replays in `GameState`;
   - every exhaustive dead-end example deadlocks when replayed in `GameState`;
   - every trap is live and deadlocks the game as described above;
   - levels without traps have dead-end rate 0, and, where the search finished,
     0 dead states;
   - the fingerprint is unique across the candidate campaign and differs from
     every original level;
   - the highest similarity is at most 0.27 (pass threshold 0.5).
6. Determinism: rebuilding levels 4, 12 and 21 gives identical levels.
7. `assets/levels.bin` bytes are unchanged after the run.

## Limits and trade-offs

- **Search limits.** L21's exhaustive search hit its 400,000-state cap. Its
  two traps are proven by direct game replay, but the claim that L21 has no
  *other* dead ends is not proven. For L24 the search completed and found 4
  dead states (from 2 traps).
- **Estimates.** Dead-end rates are random-play estimates from the profiler,
  not exact probabilities.
- **Hints.** Hints and the magic wand follow the stored order, which is the
  construction order and may not be the most natural one.
- **Fill.** Small boards are sparser than the originals (fill 0.71–0.72 on 4,
  5, 6 and 8, against about 0.9). This is a deliberate trade for larger cells
  and fewer arrows.
- **Feature changes.** L19 lost its single pair, and L21–L24 have fewer
  directional dots than the originals. In exchange, the dots they have are
  all live.
- **Construction.** The boards come from a seeded search with structural
  rules, not from hand design.
- **No player testing.** The visual check was light theme only, at 1×, in the
  test harness, not on a device. Dark theme and RTL were not rendered for
  these candidates. Board rendering is the same code for both locales, but
  that was not visually confirmed.
- No claim is made that these levels are more enjoyable. That requires player
  testing.
