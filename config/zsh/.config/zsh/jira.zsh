# Jira entrypoint: open tmux window, browse my work, or sync snapshots.
jira() {
  case "${1:-}" in
    "")
      bash "$HOME/.config/tmux/scripts/jira-session"
      ;;
    -h|--help|help)
      cat <<'EOF'
jira         open jira window in daily session
jira backlog sync and browse jira backlog
jira mywork  fzf picker of my tasks assigned
jira sync    sync jira data snapshot

direct commands:
jira-backlog fzf picker of jira backlog
jira-mywork  fzf picker of my tasks assigned
jira-sync    sync jira data snapshot
EOF
      ;;
    backlog)
      shift
      jira-backlog "$@"
      ;;
    mywork)
      shift
      jira-mywork "$@"
      ;;
    sync)
      shift
      jira-sync "$@"
      ;;
    *)
      echo "Unknown jira subcommand: $1" >&2
      echo >&2
      jira --help
      return 1
      ;;
  esac
}
