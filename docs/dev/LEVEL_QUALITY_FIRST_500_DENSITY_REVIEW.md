# First 500 — density & zigzag review (v2)

Status: **development candidate** at
`build/candidates/first_500_quality_v2/`.  
Does **not** modify `assets/levels.bin` or overwrite
`build/candidates/first_500_quality/` / prior phase bins.

Playtest gate for v1 remains separate; this pass addresses **content density**
and **path variety**, not human enjoyment claims.

---

## 1. Verified cause of sparse boards

**Not** a decode/encode loss, rendering bug, or mask under-utilization in the
runtime loader.

**Cause:** reverse-construction briefs in Phases 1B / mid / 2A–2E hardcoded
low `CandidateBrief.arrows` and moderate `fill`, while selection strongly
penalized head crowding. Typical normals targeted **~18–30** arrows while
production medians sit near **~38–55**. Phase 2A normals used
`arrows: 20 + band * 2` (~20–28) vs production median **52**.

**Level 50 (decoded):**

| | Production | first_500_quality (v1) |
|---|---|---|
| Arrow records | **34** | **15** (44%) |
| Path cells | 133 | 105 |
| Avg path length | 3.91 | 7.00 |
| Bends 0/1/2/3+ | 6/18/8/2 | 1/4/4/6 |
| Grid / mask | 26 / plus | same |

v1 arrows were **fewer but longer and more bent** — boards looked empty
because of **record count**, not missing zigzags. Band medians 25–250 looked
unchanged only because **only 23 mid IDs** differed; **251–500** medians fell
to **~54–58%** of production.

Multi-turn share 251–500: production ~0.72, v1 ~0.91 (high bends per arrow,
still underfilled).

---

## 2. v2 strategy

| Lever | Change |
|---|---|
| Arrow targets | ~90% of production (75% floor); overcrowded specials (≥120 arrows) capped ~56–95 with documented exception |
| Fill | ≥0.88 normals / ≥0.84 specials |
| Straightness | 0.34 + turn preference in `_grow` |
| Placement | More miss retries; bend bonus in `_score`; softer crowd weight |
| Phase 2A traps | Thinned normals to ~40% (`level % 5 ∈ {0,2}`) |
| Fallback | If densify fails → **production** (dense) or Phase 1B for early — never keep sparse v1 by default |
| Output | `build/candidates/first_500_quality_v2/` only |

Code: `density_policy.dart`, `first500_v2.dart`, `first500_v2_test.dart`,
`candidate_builder.dart` (zigzag / density placement).

---

## 3–13. Results (filled by build)

See machine-readable:

| File | Content |
|---|---|
| `level_profile.json` | Per-level 1–500 arrows, ratio, multiTurn, peel, source |
| `exceptions.json` | Documented floors / fallbacks |
| `source_map.json` | Per-level source tag |
| `campaign_audit.json` | Strict audit |
| `build_log.txt` | Generator log |

### Commands

```bash
flutter test test/candidates/first500_v2_test.dart
# snapshots (after bin exists):
OUT=build/candidates/first_500_quality_v2/snapshots
LEVELS=50,12,24,210,217,220,251,270,301,350,400,450,500
BOARD_SNAPSHOT_BIN=assets/levels.bin BOARD_SNAPSHOT_DIR=$OUT/original \
  BOARD_SNAPSHOT_VIEWPORTS=phone BOARD_SNAPSHOT_THEMES=light \
  BOARD_SNAPSHOT_LEVELS=$LEVELS flutter test test/visual/board_snapshot_test.dart
BOARD_SNAPSHOT_BIN=build/candidates/first_500_quality/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=$OUT/v1 ...
BOARD_SNAPSHOT_BIN=build/candidates/first_500_quality_v2/levels_candidate.bin \
  BOARD_SNAPSHOT_DIR=$OUT/v2 ...
```

### SHA baselines (pre-build)

- Production `assets/levels.bin`: `bfac49331846e1cd4f588d4a08007fbacc8a3d68`
- v1 `first_500_quality`: `fb5a6ab4b10cfd5d8fced40ba2f3eb7a4771dd84`

### Limitations

- Human playtesting still required before claiming enjoyment.
- Overcrowded specials intentionally below 75% restore.
- Incomplete reachability on large specials unchanged.
- Arabic RTL / physical device not claimed unless performed.
- Do not start 501–1000 remediation from this density pass alone.

### Gate note

Density v2 improves content metrics. Campaign acceptance for shipping still
requires the playtest gate on a chosen candidate (v1 or v2).
