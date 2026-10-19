#!/usr/bin/env bash
# Repository hygiene checks for CI and local pre-release runs.
#   - no signing material, service configs or local secrets are tracked
#   - no private key blocks or keystore passwords are committed
#   - assets/levels.bin matches the pinned checksum
# Usage: scripts/ci/check_repo.sh   (from the repository root)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
status=0

error() {
  status=1
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    echo "::error::$1"
  else
    echo "ERROR: $1" >&2
  fi
}

forbidden=$(git ls-files -- \
  '*.jks' '*.keystore' '*.p12' '*.pem' '*.aab' '*.apk' \
  '**/key.properties' 'key.properties' \
  '**/local.properties' 'local.properties' \
  '**/google-services.json' 'google-services.json' \
  '**/GoogleService-Info.plist' 'GoogleService-Info.plist' \
  'lib/core/ad_secrets.dart')
if [[ -n "$forbidden" ]]; then
  while IFS= read -r f; do
    error "tracked file must not be committed: $f"
  done <<<"$forbidden"
fi

# Prints file names only, never matching content.
leaks=$(git grep -lI -E \
  -e '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' \
  -e '^(storePassword|keyPassword)=[^[:space:]]' \
  -- . ':!scripts/ci/check_repo.sh' || true)
if [[ -n "$leaks" ]]; then
  while IFS= read -r f; do
    error "possible committed secret (private key or signing password): $f"
  done <<<"$leaks"
fi

pin=scripts/release/levels.bin.sha256
if [[ ! -f assets/levels.bin ]]; then
  error "assets/levels.bin is missing"
elif [[ ! -f "$pin" ]]; then
  error "$pin is missing"
else
  expected=$(awk '{print $1}' "$pin")
  if command -v sha256sum >/dev/null; then
    actual=$(sha256sum assets/levels.bin | awk '{print $1}')
  else
    actual=$(shasum -a 256 assets/levels.bin | awk '{print $1}')
  fi
  if [[ "$actual" != "$expected" ]]; then
    error "assets/levels.bin changed (sha256 $actual, pinned $expected). \
If the campaign was regenerated deliberately, run the full audit and update $pin \
(see docs/dev/RELEASE_CHECKLIST.md)."
  else
    echo "assets/levels.bin sha256 matches $pin"
  fi
fi

if [[ $status -eq 0 ]]; then
  echo "Repository checks passed."
fi
exit $status
