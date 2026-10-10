#!/usr/bin/env bash
# Verify the permissions *inside* the final AppImage without changing the
# bundle (or invalidating its Tauri updater signature). Used in CI for #879.
set -euo pipefail

mapfile -d '' images < <(
  find src-tauri/target -type f -path '*/release/bundle/appimage/*.AppImage' -print0
)
if (( ${#images[@]} == 0 )); then
  echo "::error::No bundled AppImage found for permission verification"
  exit 1
fi

scratch=""
cleanup() {
  if [[ -n "$scratch" ]]; then rm -rf "$scratch"; fi
}
trap cleanup EXIT

for image in "${images[@]}"; do
  archive="$(realpath "$image")"
  scratch="$(mktemp -d)"
  echo "Checking executable permissions inside ${image}"
  (cd "$scratch" && "$archive" --appimage-extract >/dev/null)
  appdir="$scratch/squashfs-root"

  if [[ ! -e "$appdir/AppRun" ]]; then
    echo "::error::AppRun missing from ${image}"
    exit 1
  fi
  if [[ "${STABLE_APPIMAGE:-false}" == "true" && ! -f "$appdir/AppRun.wrapped" ]]; then
    echo "::error::Stable AppImage has no AppRun.wrapped: ${image}"
    exit 1
  fi

  checked=0
  while IFS= read -r -d '' launcher; do
    checked=$((checked + 1))
    mode="$(stat -L -c '%a' "$launcher")"
    other="${mode: -1}"
    if (( (8#$other & 5) != 5 )); then
      echo "::error::${launcher#"$appdir/"} has permissions $mode in ${image}; expected world-readable and executable (e.g. 755)"
      exit 1
    fi
  done < <(find "$appdir" -maxdepth 1 \( -type f -o -type l \) -name 'AppRun*' -print0)
  if (( checked == 0 )); then
    echo "::error::No AppRun launcher files found in ${image}"
    exit 1
  fi

  rm -rf "$scratch"
  scratch=""
done
echo "AppImage launcher permissions verified"
