#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TV_DIR=${TV_DIR:-"$ROOT/sources/TV"}
SOURCE_REFS=${SOURCE_REFS:-"$ROOT/build/source-refs.json"}
DIST=${DIST:-"$ROOT/dist"}
RUN_NUMBER=${GITHUB_RUN_NUMBER:-local}
RUN_URL=${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-iptvorganization/TV-AutoBuild}/actions/runs/${GITHUB_RUN_ID:-local}

rm -rf "$DIST"
mkdir -p "$DIST"

leanback=$(find "$TV_DIR/app/build/outputs/apk/leanbackArmeabi_v7a/release" -maxdepth 1 -type f -name '*.apk' -print -quit)
mobile=$(find "$TV_DIR/app/build/outputs/apk/mobileArm64_v8a/release" -maxdepth 1 -type f -name '*.apk' -print -quit)
test -n "$leanback" && test -s "$leanback"
test -n "$mobile" && test -s "$mobile"

cp "$leanback" "$DIST/TV-leanback-armeabi-v7a.apk"
cp "$mobile" "$DIST/TV-mobile-arm64-v8a.apk"
cp "$SOURCE_REFS" "$DIST/SOURCE_REFS.json"
(
  cd "$DIST"
  sha256sum TV-leanback-armeabi-v7a.apk TV-mobile-arm64-v8a.apk > SHA256SUMS.txt
)

version_name=$(sed -n 's/^[[:space:]]*versionName[[:space:]]*"\([^"]*\)".*/\1/p' "$TV_DIR/app/build.gradle" | head -1)
version_code=$(sed -n 's/^[[:space:]]*versionCode[[:space:]]*\([0-9]*\).*/\1/p' "$TV_DIR/app/build.gradle" | head -1)

cat > "$DIST/RELEASE_NOTES.md" <<EOF_NOTES
Automated public build of TV ${version_name:-unknown} (${version_code:-unknown}).

Source commits:
- TV: $(jq -r '.sources.TV.sha' "$SOURCE_REFS")
- media: $(jq -r '.sources.media.sha' "$SOURCE_REFS")
- VividLib: $(jq -r '.sources.VividLib.sha' "$SOURCE_REFS")
- sherpa-onnx: $(jq -r '.sources["sherpa-onnx"].sha' "$SOURCE_REFS")

Build run: ${RUN_URL}

Both APKs use the persistent TV-AutoBuild release signing key stored as GitHub Actions secrets. Verify files with SHA256SUMS.txt.
EOF_NOTES

echo "release_name=TV ${version_name:-unknown} autobuild ${RUN_NUMBER}" >> "${GITHUB_OUTPUT:-/dev/null}"
