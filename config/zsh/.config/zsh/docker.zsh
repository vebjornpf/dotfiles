# Show running containers as blocks; optionally filter by text in any field.
dps() {
  setopt local_options pipe_fail

  local color=0
  [[ -t 1 && -z ${NO_COLOR:-} ]] && color=1

  docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' |
    awk -F '\t' -v pattern="${1:-}" -v color="$color" '
      pattern == "" || index($0, pattern) {
        name = $2
        if (color) name = sprintf("%c[36m%s%c[0m", 27, name, 27)

        print "------------------------------"
        print name
        print "  ID:     " $1
        print "  Image:  " $3
        print "  Status: " $4

        if ($5 == "") {
          print "  Ports:  -"
        } else {
          count = split($5, ports, /, /)
          print "  Ports:  " ports[1]
          for (i = 2; i <= count; i++) print "          " ports[i]
        }
      }
    '
}
