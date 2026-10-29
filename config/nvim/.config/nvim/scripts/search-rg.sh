#!/bin/sh
# Keep normal ignore rules, then add only environment files in a second pass.
# Excluding them from the first pass avoids duplicate files and grep matches.
rg --glob '!.env' --glob '!.env.*' --glob '!.git' "$@"
normal_status=$?
if [ "$normal_status" -gt 1 ]; then
  exit "$normal_status"
fi

rg --hidden --no-ignore --glob '.env' --glob '.env.*' --glob '!.git' "$@"
env_status=$?
if [ "$env_status" -gt 1 ]; then
  exit "$env_status"
fi
if [ "$normal_status" -eq 0 ] || [ "$env_status" -eq 0 ]; then
  exit 0
fi
exit 1
