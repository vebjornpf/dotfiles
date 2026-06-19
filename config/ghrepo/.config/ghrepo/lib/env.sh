#!/usr/bin/env bash

[[ -f "$HOME/.config/local/ghrepo.zsh" ]] && source "$HOME/.config/local/ghrepo.zsh"

require_ghrepo_org() {
  if [[ -z "${GHREPO_ORG:-}" ]]; then
    echo "GHREPO_ORG is not set" >&2
    echo "Set it in ~/.config/local/ghrepo.zsh, for example:" >&2
    echo '  export GHREPO_ORG="elhub"' >&2
    exit 1
  fi
}
