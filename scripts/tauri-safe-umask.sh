#!/usr/bin/env bash
# Issue #879: keep the bundle's launcher accessible to all users.
# This runs inside the Tauri CLI process, unlike umask in an earlier CI step.
set -euo pipefail
umask 022

if [[ "${TAURI_EXPERIMENTAL_APPIMAGE:-false}" == "true" ]]; then
  cargo tauri "$@"
else
  pnpm tauri "$@"
fi

# This runs BEFORE tauri-action can upload a release, and only reads the
# signed bundle. A bad stable AppImage must never be published.
if [[ "${1:-}" == "build" ]]; then
  if [[ "${TAURI_EXPERIMENTAL_APPIMAGE:-false}" == "true" ]]; then
    STABLE_APPIMAGE=false bash scripts/check-appimage-permissions.sh
  else
    STABLE_APPIMAGE=true bash scripts/check-appimage-permissions.sh
  fi
fi
