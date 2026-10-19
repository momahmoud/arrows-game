# Release checklist

CI runs most of this automatically (`.github/workflows/ci.yml` on pull
requests and pushes to `development`, `main`, `dev/**`, `feature/**`;
`.github/workflows/release.yml` on `v*` tags or manual dispatch). Run the same
commands locally before tagging a release. Android is the only platform in this
repository; iOS is not built or tested.

## Test tags

Tags are declared in `dart_test.yaml`.

| Tag | Contents | CI |
|---|---|---|
| *(none)* | unit, widget, codec, repository, progression, localization/RTL, purchase, repo contract tests | every run |
| `campaign` | full audit of `assets/levels.bin` plus the level quality profile ([LEVEL_QUALITY_AUDIT.md](LEVEL_QUALITY_AUDIT.md)), ~40 s | every run; strict on release |
| `slow` | legacy `LevelGenerator` regression (~7 min) | pushes and release, not PRs |
| `release` | real ad config in `lib/core/ad_secrets.dart` | release only |
| `generator` | regenerates content (writes `levels.bin`, chunk JSON, docs) | never |

Never run a bare `flutter test`: it includes `generator` tests, which rewrite
`assets/levels.bin` and other tracked files.

## Before every release

```bash
scripts/ci/check_repo.sh                     # no tracked secrets; levels.bin matches pin
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --exclude-tags generator,campaign,slow,release,candidates
CAMPAIGN_AUDIT_STRICT=1 CAMPAIGN_AUDIT_JSON=build/campaign_audit.json \
  flutter test --tags campaign
flutter test --tags slow
flutter test --tags release                  # needs your real lib/core/ad_secrets.dart
flutter build appbundle --release            # needs android/key.properties + keystore
BUNDLETOOL_JAR=/path/to/bundletool-all-1.18.3.jar REQUIRE_RELEASE_SIGNING=1 \
  scripts/release/verify_bundle.sh build/app/outputs/bundle/release/app-release.aab
git status --porcelain                       # must be empty
```

`verify_bundle.sh` confirms the packaged `levels.bin` is byte-identical to the
pinned file, all declared images/audio/fonts are packaged, the build is AOT
(no debug artifacts), the package is `com.arrows.fluxylabs`, the version
matches `pubspec.yaml`, the app is not debuggable, the AdMob app ID is not
Google's test ID, and the bundle is not debug-signed. It never uploads.

Upload to Google Play manually after all checks pass.

## Reading the campaign audit

The audit (`test/campaign_audit_test.dart`, using `CampaignAudit.auditBytes`)
decodes every level with the game's own codec and rules and prints counts,
histograms, failing IDs with reasons, and any release blockers.

- **Structurally invalid, confirmed unsolvable, duplicate fingerprint,
  fallback, or count mismatch**: real content defects. Do not release. Fix the
  generator or the specific levels, then regenerate deliberately.
- **Unverified**: the solver hit its state limit (8000) before finding a
  solution. This is *not* proof the level is unsolvable. Pull-request CI
  allows it; release (`CAMPAIGN_AUDIT_STRICT=1`) requires zero unverified
  levels. Check the listed IDs by playing them or with a larger solver budget
  before releasing.
- **Header/format error**: `assets/levels.bin` is truncated or has the wrong
  magic/version. Restore it from git.

`CAMPAIGN_AUDIT_JSON=<path>` writes the full report (per-level solvability,
histograms, blockers) as JSON. CI uploads it as the `campaign-audit` artifact.

## Changing the campaign deliberately

CI never regenerates `assets/levels.bin`; `scripts/ci/check_repo.sh` fails if
it changes without updating the pin. To ship a new campaign:

1. Regenerate it as described in [CAMPAIGN_GENERATION.md](CAMPAIGN_GENERATION.md).
2. Run the strict audit above until it reports no blockers.
3. Update the pin:
   `shasum -a 256 assets/levels.bin > scripts/release/levels.bin.sha256`
4. Update level-count and size claims in `README.md` if they changed
   (`test/release/repo_contract_test.dart` checks them).
5. Commit the binary, the pin, and the docs together.

## Required GitHub secrets (release workflow)

| Secret | Contents |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64` of the upload keystore |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_STORE_PASSWORD` | keystore password |
| `GOOGLE_SERVICES_JSON_BASE64` | `base64` of `android/app/google-services.json` |
| `AD_SECRETS_DART_BASE64` | `base64` of `lib/core/ad_secrets.dart` |
| `ADMOB_APP_ID` | optional; overrides the manifest default in `android/app/build.gradle.kts` |

`scripts/release/write_secrets.sh` writes these files on the runner without
printing values. Pull-request CI needs no secrets: it compiles against
`lib/core/ad_secrets_example.dart`.
