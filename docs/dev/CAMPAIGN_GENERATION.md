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
