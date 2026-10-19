# Level quality remediation, phase 2A (levels 251–300)

Status: **development candidate only.** Pilot rework of the mid-campaign
plateau band. `assets/levels.bin` was not modified. Phase 1 / 1B baselines
under `build/candidates/early_phase1/` and `early_phase1b/` were left in place.

Context: [LEVEL_QUALITY_AUDIT.md](LEVEL_QUALITY_AUDIT.md) found that normal
levels stop getting meaningfully harder after ~250, and boss/god levels
plateau after ~100. In 251–300 every production level has random-play
**dead-end rate 0** despite directional dots — dots do not create competing
order decisions.

## Reproducing

```bash
flutter test test/candidates/phase2a_test.dart
```

Output (gitignored) under `build/candidates/phase2a_251_300/`:

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level candidate campaign |
| `candidates.json` | Per-level original vs candidate profiles, traps, silhouette, reachability |
| `boards.txt` | ASCII boards for 251–300 |
| `campaign_audit.json` | Strict audit of the candidate campaign |
| `snapshots/original`, `candidate` | Phone 366×600 light renders of representative levels |
| `sheet_representative.png`, `sheet_specials.png` | Contact sheets |

Code: `test/candidates/phase2a.dart`, `phase2a_test.dart`, plus shared
`candidate_builder.dart` / `TrapFairness` (constructive solution-path fallback
for large boards).

## Original baseline (Task 1)

From `build/level_quality.json` (real rules via `LevelQuality`):

| Band | Type | Median arrows | Peel | Trap rate | Dir. dots | Pairs | Dead-end rate | Cell dp |
|---|---|---|---|---|---|---|---|---|
| 201–250 | normal | 49 | 17 | 0.79 | 7 | 4 | **0.00** | 16.5 |
| 251–300 | normal | 49 | 17 | 0.78 | 6 | 4 | **0.00** | 16.5 |
| 301–350 | normal | 50 | 16 | 0.78 | 5 | 4 | **0.00** | 16.5 |
| 251–300 | boss | 101 | 24 | 0.82 | 17 | 12 | **0.00** | 8.2 |
| 251–300 | god | 114 | 26 | 0.82 | 16 | 14 | **0.00** | 8.2 |

Confirmed problems in 251–300:

- **No order deadlocks.** All 50 levels have dead-end rate 0. Without a
  competing consumer for a deflector, tap order cannot strand the board.
- **Plateau vs 201–250.** Normal medians are essentially flat (49 arrows,
  peel 17).
- **Specials are size, not role.** Bosses 79–189 arrows / peel 14–52; gods
  36–129 / peel 6–37. Crowding 0.69–0.88; cells ~8.2 dp on most specials.
- **L290 god is weak.** Sun mask (~248 cells): 36 arrows, peel **6**, trap
  rate 0.59 — below neighbouring normals (peel 13–16).
- **L273 boss peel 14** is below several normals in the same decade.

Dead-end rate is a 32-playout heuristic. Exhaustive reachability on these
large boards usually hits a search cap; “0 dead ends” from random play is
still a strong signal that order rarely matters.

## Design (Tasks 2–4)

### Progression across five decades

| Decade | Role |
|---|---|
| 251–260 | Introduce live traps on alternate normals; bosses 1 trap; gods 2 traps |
| 261–270 | Most normals have 1 trap; denser detours/pairs |
| 271–280 | Same trap budget; more detours on late normals |
| 281–290 | Continue; **rescue L290** with a live trap on the small sun |
| 291–300 | Hold decision density; end on breather L300 |

**Breathers** (order-independent): 254, 260, 268, 275, 282, 289, 296, 300.

Not every level is a trap. Breaths have dead-end rate 0 by design.

### Difficulty is not arrow count

Candidates use **fewer** arrows than production (readable density) and add
**intentional order traps** (shared deflector + waste arrow) that are:

- reachable along the stored solution (constructive proof when BFS caps out),
- confirmed to deadlock in `GameState` when the waste is taken,
- required to leave ≥1 competing free move at the decision.

Bosses/gods keep original masks with outline bias; they carry more traps and
deeper peels than surrounding normals where the silhouette allows.

### Variety

Fingerprints compared against the full candidate campaign and originals.
Nearest arrow IoU in-batch max **0.21** (L274 vs L291); specials ≤0.17.
Shape identities and the 7-level boss/god schedule are unchanged.

## Candidate vs original batch summary

Median over each decade (all types mixed):

| Decade | Arrows o→c | Peel o→c | Dead-end o→c | Live traps placed |
|---|---|---|---|---|
| 251–260 | 53→31 | 20→11 | 0.00→0.31 | 6 |
| 261–270 | 55→28 | 18→11 | 0.00→0.34 | 11 |
| 271–280 | 57→34 | 22→10 | 0.00→0.38 | 12 |
| 281–290 | 49→28 | 16→9 | 0.00→0.34 | 10 |
| 291–300 | 52→29 | 19→11 | 0.00→0.38 | 10 |

**Trade-off (intentional):** peel length fell because boards are less densely
packed. What rose is **decision risk** (dead-end rate from live traps) and
**head readability** (crowding typically 0.7+ → ~0.1–0.3). Harder is not the
goal; clearer order puzzles are.

All **49** placed traps passed `TrapFairness.ok` (reachable decision,
competing move, wrong tap deadlocks in `GameState`).

## Boss and god roles (Task 3)

| L | Shape | Arrows o→c | Peel o→c | Open o→c | Dead o→c | Traps | Note |
|---|---|---|---|---|---|---|---|
| 252 | puzzlePiece | 135→68 | 35→16 | 27→15 | 0→0.31 | 1 | Clearer piece silhouette |
| 255 | dhow | 114→57 | 27→13 | 29→10 | 0→0.41 | 2 | |
| 259 | drum | 189→76 | 52→22 | 24→15 | 0→0.31 | 1 | Extreme density cut |
| 262 | cloud | 78→53 | 30→12 | 9→13 | 0→0.50 | 2 | |
| 266 | testTube | 101→44 | 16→12 | 31→16 | 0→0.38 | 1 | |
| 269 | crowBird | 101→60 | 20→10 | 24→8 | 0→0.41 | 2 | |
| 273 | rat | 79→56 | 14→10 | 17→16 | 0→0.53 | 2 | Was shallow vs normals |
| 276 | ufo | 115→53 | 37→13 | 24→10 | 0→0.53 | 2 | |
| 280 | otter | 96→56 | 30→13 | 13→13 | 0→0.53 | 2 | |
| 283 | dove | 118→68 | 24→16 | 29→13 | 0→0.59 | 2 | |
| 287 | ant | 95→52 | 20→10 | 26→12 | 0→0.56 | 2 | |
| **290** | **sun** | **36→27** | **6→7** | 5→6 | **0→0.47** | **1** | Small mask (~248 cells); peel capped; now has a live trap |
| 294 | fire | 137→55 | 24→12 | 31→14 | 0→0.53 | 2 | |
| 297 | bactrianCamel | 129→76 | 26→15 | 29→13 | 0→0.50 | 2 | |

Cell sizes match production (masks unchanged). Crowding on specials dropped
sharply. At ~8.2 dp, specials remain hard to read as animals; lower fill makes
outlines slightly clearer than the “texture” originals (see contact sheets).

## Per-level index

Full metrics for every level 251–300 live in
`build/candidates/phase2a_251_300/candidates.json` (original + candidate
profiles, trap fairness, silhouette, nearest IoU, ASCII board). Intents and
breather flags are stored there.

Representative pattern:

- **Breather** (e.g. L300): 52→29 arrows, peel 17→14, dead 0, traps 0.
- **Trap normal** (e.g. L270): 48→25 arrows, peel 18→7, dead 0→0.31, 1 trap.
- **Boss** (e.g. L259): 189→76 arrows, peel 52→22, dead 0→0.31, 1 trap.
- **God rescue L290**: peel 6→7, dead 0→0.47, 1 fair trap on sun.

## Validation (Tasks 5–6)

`flutter test test/candidates/phase2a_test.dart`: **8 of 8 passed.**

- Exactly 1,000 levels; IDs, grids, difficulty, `maskShape`, `patternName` match.
- Levels **1–250 and 301–1000** byte-identical to production.
- Levels **251–300** differ from production.
- Phase 1 / 1B bins present and different from Phase 2A.
- Strict `CampaignAudit`: 1000 valid, 1000 confirmed solvable, 0 unverified,
  0 fallback, 0 duplicate fingerprints, no blockers; changed levels
  `storedSolutionValid`.
- Stored solution + independent DFS replay in `GameState` for every changed
  level.
- All intended traps fair and deadlocking; breathers dead-end rate 0.
- Determinism for 251, 273, 290.
- `assets/levels.bin` SHA-1 unchanged: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`.

### Solver / search limits

- Exhaustive reachability used cap **200,000**. **13 specials** did not finish
  (`reachable.complete=false`): 252, 255, 259, 262, 266, 269, 273, 276, 280,
  283, 287, 294, 297. Their traps were still proven via constructive
  solution-path + `GameState` deadlock. Absence of *other* dead ends on those
  boards is **not** proven.
- Dead-end rates remain random-play estimates (32 playouts).

## Visual checks

- Phone viewport **366×600**, harness only (not a physical device).
- Light theme: original + candidate for representative set including specials,
  breathers, early/mid/late.
- Dark theme / RTL: not rendered for this batch. Board layout is grid-centred
  and not locale-driven; that was not re-verified with screenshots here.

Contact sheets: `sheet_representative.png`, `sheet_specials.png`.

## Limits and human playtesting needs

- Peel depth is lower than production; players who equated “hard” with long
  peels may feel the band easier until they hit traps.
- Specials at 8.2 dp remain cramped; readability gain is from lower density,
  not larger cells.
- L290 cannot match neighbour peel depth on the sun mask; its upgrade is the
  live trap, not chain length.
- No claim of greater enjoyment without player testing.
- Whether to merge into production is a separate decision.

## Files changed

- `test/candidates/phase2a.dart` (new)
- `test/candidates/phase2a_test.dart` (new)
- `test/candidates/early_phase1b.dart` — constructive trap fallback for large boards
- `docs/dev/LEVEL_QUALITY_REMEDIATION_PHASE2A.md` (this report)

Artifacts: `build/candidates/phase2a_251_300/`.
