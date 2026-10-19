#!/usr/bin/env bash
# Verifies a release Android App Bundle without uploading or publishing it.
#
# Usage: BUNDLETOOL_JAR=/path/bundletool.jar \
#          scripts/release/verify_bundle.sh build/app/outputs/bundle/release/app-release.aab
# Env:
#   BUNDLETOOL_JAR           required; bundletool-all jar used to read the manifest
#   REQUIRE_RELEASE_SIGNING  1 = fail on debug-signed or unsigned bundles (CI release)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
aab=${1:-build/app/outputs/bundle/release/app-release.aab}
status=0
fail() {
  status=1
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then echo "::error::$1"; else echo "FAIL: $1" >&2; fi
}
ok() { echo "ok: $1"; }

[[ -f "$aab" ]] || { fail "bundle not found: $aab"; exit 1; }
[[ -n "${BUNDLETOOL_JAR:-}" && -f "$BUNDLETOOL_JAR" ]] ||
  { fail "BUNDLETOOL_JAR must point to a bundletool jar"; exit 1; }

entries=$(mktemp)
trap 'rm -f "$entries"' EXIT
unzip -Z1 "$aab" >"$entries"

sha256() { if command -v sha256sum >/dev/null; then sha256sum | awk '{print $1}'; else shasum -a 256 | awk '{print $1}'; fi; }

# Campaign asset: byte-identical to the committed, pinned file.
packaged=base/assets/flutter_assets/assets/levels.bin
if grep -qx "$packaged" "$entries"; then
  want=$(awk '{print $1}' scripts/release/levels.bin.sha256)
  have=$(unzip -p "$aab" "$packaged" | sha256)
  committed=$(sha256 <assets/levels.bin)
  if [[ "$have" == "$want" && "$have" == "$committed" ]]; then
    ok "levels.bin packaged and matches pinned sha256"
  else
    fail "packaged levels.bin sha256 $have != pinned $want / committed $committed"
  fi
else
  fail "levels.bin is not packaged ($packaged)"
fi

# Declared assets (pubspec) and fonts (FontManifest.json) are all packaged.
missing=$(
  git ls-files ':(glob)assets/images/*' ':(glob)assets/images/icons/*' ':(glob)assets/audio/*' |
    python3 -c '
import json, subprocess, sys, urllib.parse
aab, listing = sys.argv[1], sys.argv[2]
entries = set(open(listing).read().split("\n"))
prefix = "base/assets/flutter_assets/"
def packaged(path):
    return prefix + path in entries or prefix + urllib.parse.quote(path) in entries
wanted = [line.strip() for line in sys.stdin if line.strip()]
fonts = json.loads(subprocess.run(["unzip", "-p", aab, prefix + "FontManifest.json"],
                                  check=True, capture_output=True).stdout)
wanted += [f["asset"] for family in fonts for f in family["fonts"]]
if not any("PlaypenSansArabic" in w for w in wanted):
    print("PlaypenSansArabic font family")
for w in wanted:
    if not packaged(w):
        print(w)
' "$aab" "$entries"
) || fail "could not read FontManifest.json from bundle"
if [[ -n "$missing" ]]; then
  while IFS= read -r m; do fail "asset not packaged: $m"; done <<<"$missing"
else
  ok "declared images, icons, audio and fonts packaged"
fi

# Release AOT build, not a debug/JIT build.
grep -qx 'base/lib/arm64-v8a/libapp.so' "$entries" &&
  ok "AOT libapp.so (arm64-v8a) present" || fail "base/lib/arm64-v8a/libapp.so missing"
if grep -qE 'flutter_assets/(kernel_blob\.bin|isolate_snapshot_data|vm_snapshot_data)$' "$entries"; then
  fail "debug/JIT artifacts packaged (kernel_blob.bin or snapshot data)"
else
  ok "no debug/JIT Flutter artifacts"
fi
if grep -qE 'flutter_assets/assets/(level_chunks/|campaign_fingerprints\.json|.*\.txt$)' "$entries"; then
  fail "generator-only files packaged"
else
  ok "no generator-only files packaged"
fi

# Manifest: package, version, debuggable, AdMob app ID.
manifest() { java -jar "$BUNDLETOOL_JAR" dump manifest --bundle "$aab" --xpath "$1" 2>/dev/null || true; }
pkg=$(manifest '/manifest/@package')
vcode=$(manifest '/manifest/@android:versionCode')
vname=$(manifest '/manifest/@android:versionName')
debuggable=$(manifest '/manifest/application/@android:debuggable')
admob=$(manifest "/manifest/application/meta-data[@android:name='com.google.android.gms.ads.APPLICATION_ID']/@android:value")

version=$(awk '/^version:/{print $2}' pubspec.yaml)
want_name=${version%%+*}
want_code=${version##*+}

[[ "$pkg" == "com.arrows.fluxylabs" ]] && ok "package $pkg" || fail "package is '$pkg', expected com.arrows.fluxylabs"
[[ "$vname" == "$want_name" && "$vcode" == "$want_code" ]] &&
  ok "version $vname ($vcode) matches pubspec" ||
  fail "version '$vname' ($vcode) does not match pubspec $version"
[[ -z "$debuggable" || "$debuggable" == "false" ]] && ok "not debuggable" || fail "android:debuggable=$debuggable"
if [[ "$admob" =~ ^ca-app-pub-[0-9]{16}~[0-9]{10}$ && "$admob" != *3940256099942544* ]]; then
  ok "AdMob APPLICATION_ID is a production ID"
else
  fail "AdMob APPLICATION_ID is missing, malformed or Google's test ID"
fi

# Signing: never accept the debug key for a release.
cert=$(keytool -printcert -jarfile "$aab" 2>/dev/null || true)
if [[ -z "$cert" || "$cert" == *"Not a signed jar file"* ]]; then
  signer="unsigned"
elif [[ "$cert" == *"CN=Android Debug"* ]]; then
  signer="debug"
else
  signer="release"
fi
if [[ "$signer" == "release" ]]; then
  ok "signed with a non-debug certificate"
elif [[ "${REQUIRE_RELEASE_SIGNING:-0}" == "1" ]]; then
  fail "bundle is $signer-signed"
else
  echo "warn: bundle is $signer-signed (set REQUIRE_RELEASE_SIGNING=1 to fail)"
fi

[[ $status -eq 0 ]] && echo "Bundle verification passed: $aab"
exit $status
