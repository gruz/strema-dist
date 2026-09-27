#!/bin/bash
# Publish the helper binaries in this directory as a GitHub release
# of gruz/strema-dist. Regenerates SHA256SUMS.txt automatically — install.sh
# on devices uses it both to detect non-canonical on-device builds and to
# verify downloaded assets, so it must always be part of the release.
#
# Usage:
#   ./publish.sh           # bump patch of the latest release (v1.0.0 -> v1.0.1)
#   ./publish.sh v1.2.0    # explicit tag
set -e
cd "$(dirname "$0")"
REPO="gruz/strema-dist"

for f in dzyga dzyga_web; do
    [ -f "$f" ] || { echo "❌ $f not found in $(pwd)"; exit 1; }
done

sha256sum dzyga dzyga_web > SHA256SUMS.txt
cat SHA256SUMS.txt

TAG="${1:-}"
# No-op when the binaries are identical to the latest release — otherwise
# every run would mint a new tag with the same payloads.
remote_sums=$(curl -fsSL "https://github.com/$REPO/releases/latest/download/SHA256SUMS.txt" 2>/dev/null || true)
if [ -z "$TAG" ] && [ -n "$remote_sums" ] && [ "$remote_sums" = "$(cat SHA256SUMS.txt)" ]; then
    echo "✅ Binaries unchanged — the latest release already has them. Nothing to do."
    exit 0
fi
if [ -z "$TAG" ]; then
    last=$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || true)
    if [ -n "$last" ]; then
        TAG=$(echo "$last" | awk -F. -v OFS=. '{$NF=$NF+1; print}')
    else
        TAG="v1.0.0"
    fi
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    gh release upload "$TAG" dzyga dzyga_web SHA256SUMS.txt --repo "$REPO" --clobber
    echo "✅ Assets updated on existing release $TAG"
else
    gh release create "$TAG" dzyga dzyga_web SHA256SUMS.txt --repo "$REPO" \
        --title "strema helper binaries $TAG" \
        --notes "$(md5sum dzyga dzyga_web)"
    echo "✅ Release $TAG published"
fi

# Track the checksum file in git for provenance; binaries stay release-only.
if git rev-parse --git-dir >/dev/null 2>&1; then
    git add SHA256SUMS.txt publish.sh .gitignore README.md 2>/dev/null || true
    git diff --cached --quiet || git commit -m "sums for $TAG"
    git push -q || true
fi
