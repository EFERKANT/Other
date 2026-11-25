#!/usr/bin/env bash
# site/ içindeki yer tutucuları doldurur.
# Kullanım:
#   tool/fill_site.sh ANDROID_PAKETI PLAY_SHA256 APPLE_TEAM_ID IOS_BUNDLE_ID APP_STORE_ID
set -euo pipefail
if [ $# -ne 5 ]; then
  sed -n '3,4p' "$0"
  exit 1
fi
cd "$(dirname "$0")/../site"
for f in .well-known/assetlinks.json .well-known/apple-app-site-association redirect.js; do
  sed -i.bak \
    -e "s|__ANDROID_PACKAGE__|$1|g" \
    -e "s|__PLAY_APP_SIGNING_SHA256__|$2|g" \
    -e "s|__APPLE_TEAM_ID__|$3|g" \
    -e "s|__IOS_BUNDLE_ID__|$4|g" \
    -e "s|__APP_STORE_ID__|$5|g" "$f"
  rm -f "$f.bak"
done
if grep -rn --exclude=README.md "__[A-Z_]*__" .; then
  echo "Doldurulmamış yer tutucu kaldı." >&2
  exit 1
fi
echo "site/ hazır."
