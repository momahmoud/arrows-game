# First 500 levels — integrated quality remediation

Status: **development candidate only.** Integrates validated Phase 1B and
Phases 2A–2E with **23 selective replacements** inside levels 25–250.
Production `assets/levels.bin` is unchanged
(SHA-1 `bfac49331846e1cd4f588d4a08007fbacc8a3d68`).

**Do not start 501–1000 remediation until this candidate is playtested.**
**Do not merge into production automatically.**

Playtest worksheet / protocol: `LEVEL_QUALITY_FIRST_500_PLAYTEST.md`.  
Results gate: `LEVEL_QUALITY_FIRST_500_PLAYTEST_RESULTS.md` (pending humans).

## Reproducing

```bash
flutter test test/candidates/first500_test.dart
```

Artifacts under `build/candidates/first_500_quality/` (gitignored):

| File | Content |
|---|---|
| `levels_candidate.bin` | Full 1,000-level integrated candidate |
| `candidates.json` | Per changed-level metrics (294 records) |
| `source_map.json` | Per-level source for all 1,000 IDs |
| `band_summary.json` | Peel/arrow/crowd by decade-ish bands |
| `boundaries.json` | Metrics at range boundaries |
| `campaign_audit.json` | Strict audit |
| `mid_boards.txt` | ASCII boards for mid replacements |
| `sheet_*.png` + `snapshots/` | Visual QA |

Code: `test/candidates/first500_mid.dart`, `first500_integrate.dart`,
`first500_test.dart`.

## 1. Verified status of prior phases

| Phase | Range | Binary | Report | Range-only vs production | Notes |
|---|---|---|---|---|---|
| 1B | 4–24 | `early_phase1b/levels_candidate.bin` | PHASE1B.md | OK | Preferred over Phase 1 |
| 2A | 251–300 | `phase2a_251_300/…` | PHASE2A.md | OK | **49 traps** — trap-fatigue risk |
| 2B | 301–350 | `phase2b_301_350/…` | PHASE2B.md | OK | Present and range-correct |
| 2C | 351–400 | `phase2c_351_400/…` | PHASE2C.md | OK | Median peel 12 |
| 2D | 401–450 | `phase2d_401_450/…` | PHASE2D.md | OK | Median peel 13 |
| 2E | 451–500 | `phase2e_451_500/…` | PHASE2E.md | OK | Median peel 13; better p10/p90 |

Every phase binary was decoded and checked: levels outside its edit range are
encode-identical to production; levels inside differ. Prior artifacts were
**not** overwritten.

## 2. Audit of levels 25–250

From production `build/level_quality.json`:

| Band | Median arrows | Peel | Crowd | Dead≈0 |
|---|---|---|---|---|
| 25–100 | 38 | 14 | 0.73 | mostly |
| 101–150 | 44 | 16 | 0.74 | mostly |
| 151–200 | 45 | 15 | 0.73 | mostly |
| 201–250 | 52 | 20 | 0.74 | mostly |

### Classification

**Confirmed / high-confidence (replaced):**

| Issue class | Levels |
|---|---|
| Extreme dead-end estimates | 84, 136, 158, 171, 203, **239** (0.84) |
| Critically shallow normals | 40, 50, 97, 195, 212, 230 |
| Weak / shallow specials | 31, 35, 196, 199 |
| Extreme open / crowding specials | 56, 178, 210, 217 (open 58), 220 |
| Early-mid shallow/crowd | 61, 99 |

**23 replacements** — not a full re-roll. Remaining 25–250 levels stay
production (acceptable plateau / learning / breathers).

**Suspicious (kept production; playtest):** other near-dup silhouette clusters
from the campaign audit; wide-open specials with moderate peel; `legend`
label vs measured difficulty mismatch (schedule-driven metadata — not changed).

**Acceptable:** repeated mask names that still teach mechanics; gradual peel
ramp 25→250; most normals with dead≈0 and peel ≥12.

## 3. Mid replacements (25–250) — before → after

| L | Role | Peel | Open | Dead | Crowd | Intent |
|---|---|---|---|---|---|---|
| 31 | godPair | 11→10 | 16→10 | 0→0 | 0.75→0.06 | Readable early god |
| 35 | bossChain | 13→10 | 21→11 | 0→0 | 0.91→0.33 | Less crowded boss |
| 40 | breather | 8→10 | 18→3 | 0→0 | 0.47→0 | Soft-spike repair |
| 50 | breather | 6→10 | 13→3 | 0→0 | 0.73→0.13 | Progression hole |
| 56 | bossTrap | 21→11 | **32→14** | 0→0.31 | 0.88→0.30 | Fair trap, tighter open |
| 61 | breather | 9→11 | 9→6 | 0→0 | 0.84→0.32 | Crowd repair |
| 84 | bossTrap | 18→12 | 29→11 | **0.47→0.25** | 0.84→0.15 | Fairer deadlock |
| 97 | chain | **6→9** | 10→5 | 0.34→0 | 0.74→0.35 | Deepen + clear dead |
| 99 | breather | 8→11 | 10→6 | 0→0 | 0.55→0 | |
| 136 | godTrap | 24→13 | **38→13** | 0.41→0.28 | 0.76→0.36 | Open rescue |
| 158 | trap | 11→12 | 12→3 | **0.47→0.22** | 0.71→0.35 | Fair trap |
| 171 | godTrap | 30→17 | 13→13 | **0.53→0.41** | 0.68→0.19 | Milder deadlock |
| 178 | godTrap | 23→15 | **36→18** | 0→0.41 | **0.91→0.18** | Crowd rescue |
| 195 | chain | 9→11 | 13→2 | 0→0 | 0.76→0.25 | |
| 196 | bossChain | **12→18** | 23→12 | 0→0 | 0.67→0.25 | Boss deepen |
| 199 | godPair | 13→10 | **26→10** | 0→0 | 0.78→0.19 | Open/crowd |
| 203 | bossTrap | 26→18 | 30→13 | **0.62→0.25** | 0.80→0.14 | Fairer |
| 210 | bossTrap | 16→11 | **48→16** | 0→0.38 | 0.88→0.26 | Open rescue |
| 212 | chain | 9→12 | 15→5 | 0→0 | 0.82→0.17 | |
| 217 | bossTrap | 25→15 | **58→16** | 0→0.34 | **0.93→0.20** | Extreme open |
| 220 | godTrap | 23→13 | **46→12** | 0→0.44 | **0.93→0.26** | Extreme open |
| 230 | chain | **7→11** | 13→3 | 0.34→0 | 0.69→0.21 | |
| 239 | trap | 13→11 | 11→5 | **0.84→0.41** | 0.71→0.28 | Worst dead-end |

Trade-off: L31/L35 peel dipped slightly while crowding fell sharply — mask
limits under reverse construction; documented for playtesting.

## 4. Critical review of prior candidates

### Phase 1B (4–24)
**Accepted.** Keeps smoother intro, outline-biased specials, fairer first trap
at L12. Mermaid (10) / lion (24) remain small-cell specials — playtest
readability. Not regenerated here.

### Phase 2A (251–300)
**Accepted with flag.** 49 traps / 50 levels is trap-heavy by design. Risk:
trap fatigue and repetitive decision geometry. **Not auto-thinned** in this
integration (would need a dedicated 2A refinement pass). Playtest consecutive
traps and compare to 2B’s varied roles. Boundary **250→251** drops peel
18→11 and arrows 51→29 — intentional readability shift, but abrupt.

### Phase 2B–2E (301–500)
**Accepted.** Role diversity (chain / detour / pair / trap / breather) and
lower crowding retained. Duration still below production (~13 vs ~18–20
median peel). Phase 2E’s better p10/p90 kept. Flagged shorts from 2E reports
(463, 474, 481, 487, 488) remain in the candidate for playtesting — not
silently lengthened.

## 5. Composition of `first_500_quality`

| Levels | Source | Count |
|---|---|---|
| 1–3 | Production tutorials | 3 |
| 4–24 | Phase 1B | 21 |
| 25–250 | Production + **23 mid** | 226 |
| 251–300 | Phase 2A | 50 |
| 301–350 | Phase 2B | 50 |
| 351–400 | Phase 2C | 50 |
| 401–450 | Phase 2D | 50 |
| 451–500 | Phase 2E | 50 |
| 501–1000 | Production | 500 |

Totals: **294 changed** in 1–500; **706 production** overall.

Assembly uses decoded `LevelModel` records + `encodeLevels` — no raw byte
splices. Boss/God schedule and difficulty metadata preserved.

## 6. First-500 band metrics (integrated candidate)

| Band | Median peel | p10/p90 | Short (&lt;11) | Median arrows | Median crowd |
|---|---|---|---|---|---|
| 1–24 | 7 | 3/11 | 20 | 15 | 0.17 |
| 25–100 | 13 | 10/25 | 12 | 38 | 0.71 |
| 101–150 | 16 | 11/30 | 5 | 44 | 0.73 |
| 151–200 | 15 | 11/29 | 2 | 45 | 0.71 |
| 201–250 | 18 | 13/33 | 0 | 52 | 0.73 |
| 251–300 | **10** | 7/15 | **30** | 29 | 0.14 |
| 301–350 | 12 | 10/17 | 11 | 30 | 0.18 |
| 351–400 | 12 | 10/16 | 6 | 28 | 0.16 |
| 401–450 | 13 | 10/16 | 6 | 31 | 0.19 |
| 451–500 | 13 | 11/17 | 5 | 31 | 0.19 |

Early shorts (1–24) are intentional learning peels. The **251–300** band is
the largest duration cliff vs production (Phase 2A trade-off).

## 7. Boundary findings

| Boundary | Sources | Peel | Arrows | Notes |
|---|---|---|---|---|
| 3→4 | prod→1B | 1→3 | 2→7 | Smooth tutorial→learning |
| 24→25 | 1B→prod | 12→10 | 45→34 | Mild step into mid production |
| 100→101 | prod→prod | 12→33 | 38→109 | **Special spike** (schedule god/boss) |
| 200→201 | prod→prod | 14→13 | 42→53 | Mild |
| **250→251** | prod→**2A** | **18→11** | **51→31** | **Largest candidate cliff** |
| 300→301 | 2A→2B | 14→16 | 29→53 | Recovery into 2B roles |
| 350→351 | 2B→2C | 17→13 | 73→26 | Special→normal + 2C thinning |
| 400→401 | 2C→2D | 11→13 | 24→31 | Mild continuity |
| 450→451 | 2D→2E | 13→17 | 32→73 | Into god open |
| 500→501 | 2E→prod | 16→15 | 69→52 | Back to production plateau |

`legend` difficulty labels still follow schedule position more than measured
complexity — reported, **not** rewritten.

## 8. Global validation

`flutter test test/candidates/first500_test.dart`: **10 of 10 passed.**

- Strict audit: 1000 structurally valid, 1000 confirmed solvable, 0 unverified,
  0 fallback, **0 exact duplicate fingerprints**.
- All 294 changed levels: stored-solution + DFS replay in `GameState`.
- All mid traps `TrapFairness.ok`.
- Levels 501–1000 and untouched 25–250 pockets encode-identical to production.
- Prior phase bins still present and differ from integrated.
- `assets/levels.bin` SHA-1 unchanged.

Incomplete reachability on large specials from prior phases still applies —
timeouts ≠ “no other deadlocks.”

## 9. Visual QA

- Viewport **366×600** harness (not a device).
- Sheets: `sheet_early_mid.png`, `sheet_mid_late.png`, `sheet_boundaries.png`,
  `sheet_specials_dark.png`.
- Light: original vs candidate for journey samples + mid replacements.
- Dark: specials sample.
- Arabic RTL: **not** screenshot-tested.
- Real-device: **not** performed.

## 10. Prioritized playtesting plan

Play **original vs candidate** where noted. Log: clarity, fairness, attempts,
duration feel, readability, campaign-position fit.

| Priority | IDs | Assess |
|---|---|---|
| P0 | 3–4, 12, 24–25 | Early ramp; first trap; 1B→mid handoff |
| P0 | 50, 97, 230, 239 | Mid shallow + worst dead-end repairs |
| P0 | 210, 217, 220 | Extreme-open special rescues |
| P0 | 250–251, 255, 270, 300–301 | **2A trap density / cliff** |
| P1 | 31, 35, 56, 84, 136, 196, 203 | Mid specials |
| P1 | 301, 320, 346 | 2B role variety |
| P1 | 376, 399, 434, 463, 474, 481, 487, 488 | Duration / short breathers (prior reports) |
| P1 | 350–351, 400–401, 450–451, 500–501 | Batch boundaries |
| P2 | 10, 24 (specials) | Small-cell silhouette readability |
| P2 | Sample trap-free chains in 2B–2E | Distinguish from traps |

Optional: temporary load of `build/candidates/first_500_quality/levels_candidate.bin`
via existing `BOARD_SNAPSHOT_BIN`-style override or a **dev-only** repository
switch — do not ship a production toggle or reset progress.

## 11. Commands and results

```bash
flutter test test/candidates/first500_test.dart   # 10/10 passed
dart format test/candidates/first500_*.dart
dart analyze test/candidates/first500_*.dart      # clean
# snapshots via BOARD_SNAPSHOT_BIN=… board_snapshot_test.dart
```

## 12. Limitations and recommendations before 501–1000

1. **Phase 2A trap fatigue** not mechanically thinned — needs human playtest;
   consider a dedicated 2A refinement if fatigue is confirmed.
2. **Duration gap** 251–500 vs production (~10–13 vs ~18–20 peel) remains;
   do not blindly inflate arrows.
3. **250→251 boundary** is the sharpest candidate discontinuity.
4. Mid set is **selective (23)** — many 25–250 production levels remain
   plateau-like; further passes can expand the allow-list after playtest.
5. No claim of improved enjoyment without players.
6. Incomplete reachability on large specials — honest uncertainty.

### Recommendation

Playtest P0 items → decide whether to (a) refine 2A trap density, (b) expand
mid replacements, (c) accept and proceed to 501–1000 audit under the same
integrated discipline.

## Files changed

- `test/candidates/first500_mid.dart` (new)
- `test/candidates/first500_integrate.dart` (new)
- `test/candidates/first500_test.dart` (new)
- `docs/dev/LEVEL_QUALITY_FIRST_500_REMEDIATION.md` (this report)

Artifacts: `build/candidates/first_500_quality/`.
Prior phase directories under `build/candidates/` preserved.
