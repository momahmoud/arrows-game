#!/usr/bin/env bash
# Writes release-only files from environment variables (CI secrets).
# Values are never printed. Existing files are never overwritten, so local
# developer setups are left untouched.
#
# Required:
#   ANDROID_KEYSTORE_BASE64      base64 of the upload keystore (.jks)
#   ANDROID_KEY_ALIAS
#   ANDROID_KEY_PASSWORD
#   ANDROID_STORE_PASSWORD
#   GOOGLE_SERVICES_JSON_BASE64  base64 of android/app/google-services.json
#   AD_SECRETS_DART_BASE64       base64 of lib/core/ad_secrets.dart
# Optional:
#   ADMOB_APP_ID                 AdMob app ID for the manifest (overrides the
#                                default in android/app/build.gradle.kts)
set -euo pipefail
set +x

cd "$(git rev-parse --show-toplevel)"
umask 077

required=(
  ANDROID_KEYSTORE_BASE64
  ANDROID_KEY_ALIAS
  ANDROID_KEY_PASSWORD
  ANDROID_STORE_PASSWORD
  GOOGLE_SERVICES_JSON_BASE64
  AD_SECRETS_DART_BASE64
)
missing=()
for name in "${required[@]}"; do
  [[ -n "${!name:-}" ]] || missing+=("$name")
done
if ((${#missing[@]})); then
  echo "Missing required secrets: ${missing[*]}" >&2
  exit 1
fi

keystore=android/app/upload-keystore.jks
key_properties=android/key.properties
google_services=android/app/google-services.json
ad_secrets=lib/core/ad_secrets.dart

for f in "$keystore" "$key_properties" "$google_services" "$ad_secrets"; do
  if [[ -e "$f" ]]; then
    echo "Refusing to overwrite existing $f" >&2
    exit 1
  fi
done

decode() { printf '%s' "$1" | base64 --decode >"$2"; }

decode "$ANDROID_KEYSTORE_BASE64" "$keystore"
decode "$GOOGLE_SERVICES_JSON_BASE64" "$google_services"
decode "$AD_SECRETS_DART_BASE64" "$ad_secrets"
{
  printf 'storeFile=%s\n' "$(basename "$keystore")"
  printf 'keyAlias=%s\n' "$ANDROID_KEY_ALIAS"
  printf 'keyPassword=%s\n' "$ANDROID_KEY_PASSWORD"
  printf 'storePassword=%s\n' "$ANDROID_STORE_PASSWORD"
  if [[ -n "${ADMOB_APP_ID:-}" ]]; then
    printf 'admobAppId=%s\n' "$ADMOB_APP_ID"
  fi
} >"$key_properties"

for f in "$keystore" "$google_services" "$ad_secrets"; do
  [[ -s "$f" ]] || { echo "Decoded $f is empty" >&2; exit 1; }
done
echo "Release secrets written: $keystore, $key_properties, $google_services, $ad_secrets"
