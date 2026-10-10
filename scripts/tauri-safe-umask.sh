#!/usr/bin/env bash
# Issue #879: linuxdeploy inherits this umask when creating AppRun.wrapped.
# Set it in the Tauri CLI process, not in an earlier GitHub Actions step.
set -euo pipefail
umask 022

if [[ "${TAURI_EXPERIMENTAL_APPIMAGE:-false}" == "true" ]]; then
  exec cargo tauri "$@"
fi
exec pnpm tauri "$@"
