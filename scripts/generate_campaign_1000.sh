#!/usr/bin/env bash
# Generate and validate all 1,000 campaign levels into assets/levels.bin
set -euo pipefail
cd "$(dirname "$0")/.."

rm -f assets/campaign_fingerprints.json
touch assets/campaign_fingerprints.json
echo '[]' > assets/campaign_fingerprints.json

for chunk in 1 2 3 4 5 6 7 8 9 10; do
  echo "=== Chunk $chunk ==="
  flutter test "test/verify_chunk_${chunk}_test.dart"
done

flutter test test/build_levels_bin_test.dart
flutter test test/campaign_manifest_test.dart
flutter analyze
flutter test

echo "Done. See docs/dev/level_manifest.json and assets/levels.bin"
