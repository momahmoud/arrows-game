# 1,000-level campaign generation

Uses existing `LevelGeneratorV2`, `verify_chunk_helper`, and `levels.bin` pipeline.
**Mask shapes are unchanged** — only density, arrow counts, validation, and dedup were extended.

## Generate all levels

```bash
chmod +x scripts/generate_campaign_1000.sh
./scripts/generate_campaign_1000.sh
```

Or per batch (100 levels):

```bash
flutter test test/verify_chunk_1_test.dart   # 1–100
# … through verify_chunk_10_test.dart (901–1000)
flutter test test/build_levels_bin_test.dart
flutter test test/campaign_manifest_test.dart
```

Parallel regen (faster, dedup in manifest test):

```bash
LEVELS_PART=1-1000 LEVELS_JOBS=6 SKIP_FP_DEDUP=1 \
  flutter test test/rebuild_levels_bin_test.dart
LEVELS_MERGE=1 flutter test test/rebuild_levels_bin_test.dart
```

These tests are tagged `generator` and never run in CI. After a deliberate
regeneration, run the strict campaign audit and update
`scripts/release/levels.bin.sha256` (see [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)).
Compare `LEVEL_QUALITY_JSON=build/level_quality.json flutter test test/level_quality_test.dart`
against the acceptance checklist in [LEVEL_QUALITY_AUDIT.md](LEVEL_QUALITY_AUDIT.md).

## Outputs

- `assets/levels.bin` — production (1,000 levels)
- `assets/verify_progress_chunk_*.json` — cached verified JSON
- `assets/campaign_fingerprints.json` — dedup registry
- `docs/dev/level_manifest.json` — dev manifest (after manifest test)

## Zigzag silhouettes and level roles (campaign v8 plan)

- Six zigzag silhouettes (`sawtooth`, `zigzagBand`, `snakeBand`, `waveBand`,
  `chevronStack`, `zigzagFrame`) are appended to `MaskShape` and make up about
  a third of the normal levels. `tightZigzags` / `longZigzags` path families
  give arrows more bends; about half of all normal levels use a zigzag family.
- `CampaignRoles` assigns each normal level a role: level 33 teaches order
  (`teaching`), every 8th normal level from 45 is an order `puzzle`, every
  12th from 57 is an easy `breather`, the rest are `standard` and must have no
  dead ends and a minimum chain depth that grows with the level number.
  `OrderPuzzleTuner` re-aims direction dots on puzzle boards.
- Regenerate normal levels only (tutorial, boss and god boards stay as they
  are), into a fresh folder so old results never mix in:

```bash
SKIP_FP_DEDUP=1 LEVELS_OUT=build/levels_new LEVELS_TYPES=normal \
  LEVELS_PART=4-1000 LEVELS_JOBS=7 \
  flutter test test/rebuild_levels_bin_test.dart --run-skipped -t generator \
  --plain-name "Generate levels"
LEVELS_OUT=build/levels_new LEVELS_MERGE=1 \
  flutter test test/rebuild_levels_bin_test.dart --run-skipped -t generator \
  --plain-name "Merge levels"
```

Always pass `--plain-name`: `--run-skipped` otherwise also runs the merge test
and rewrites `assets/levels.bin`. A level that fails the gates keeps its
current board in the merge. The old absolute "opening moves" validator is
bypassed for normal levels in favour of the role gate (opening share <= 0.40).
