#!/usr/bin/env sh
# lib/platform.sh — shared platform detection
# Usage: . "$REPO_ROOT/lib/platform.sh"
#        detect_platform  → "macos" | "linux" | "wsl"
#        is_wsl           → returns 0 (true) if running under WSL

detect_platform() {
  case "$(uname -s)" in
    Darwin) printf 'macos' ;;
    Linux)
      if is_wsl; then
        printf 'wsl'
      else
        printf 'linux'
      fi
      ;;
    *) printf 'unknown' ;;
  esac
}

is_wsl() {
  case "$(uname -r)" in
    *microsoft*|*Microsoft*) return 0 ;;
    *) return 1 ;;
  esac
}
