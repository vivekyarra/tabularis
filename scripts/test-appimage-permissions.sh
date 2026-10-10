#!/usr/bin/env bash
# Smoke-test both modes against a fake self-extracting AppImage.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/src-tauri/target/release/bundle/appimage"

cat > "$sandbox/src-tauri/target/release/bundle/appimage/sample.AppImage" <<'APPIMAGE'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "--appimage-extract" ]] || exit 2
mkdir -p squashfs-root
printf '#!/bin/sh\nexit 0\n' > squashfs-root/AppRun
chmod 755 squashfs-root/AppRun
if [[ "${FIXTURE_WRAPPED:-true}" == "true" ]]; then
  cp squashfs-root/AppRun squashfs-root/AppRun.wrapped
  chmod "${FIXTURE_MODE:-755}" squashfs-root/AppRun.wrapped
fi
APPIMAGE
chmod 755 "$sandbox/src-tauri/target/release/bundle/appimage/sample.AppImage"
(
  cd "$sandbox"
  STABLE_APPIMAGE=true FIXTURE_WRAPPED=true FIXTURE_MODE=755 \
    bash "$repo_root/scripts/check-appimage-permissions.sh"
  if STABLE_APPIMAGE=true FIXTURE_WRAPPED=true FIXTURE_MODE=770 \
    bash "$repo_root/scripts/check-appimage-permissions.sh"; then
    echo "Expected 0770 AppRun.wrapped to fail the audit" >&2
    exit 1
  fi
  if STABLE_APPIMAGE=true FIXTURE_WRAPPED=false \
    bash "$repo_root/scripts/check-appimage-permissions.sh"; then
    echo "Expected missing stable AppRun.wrapped to fail" >&2
    exit 1
  fi
  STABLE_APPIMAGE=false FIXTURE_WRAPPED=false \
    bash "$repo_root/scripts/check-appimage-permissions.sh"
)
echo "AppImage permission gate smoke tests passed"
