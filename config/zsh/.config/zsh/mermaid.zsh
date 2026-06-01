# Export a Mermaid source file to a PNG in Windows Documents/flowcharts.
mmdpng() {
  local transparent=0
  if [[ "$1" == "--transparent" || "$1" == "-t" ]]; then
    transparent=1
    shift
  fi

  local input="$1"
  local output_name="$2"
  local dest_dir="/mnt/c/Users/vebjorf/Documents/flowcharts"

  if [[ -z "$input" ]]; then
    echo "Usage: mmdpng [--transparent] <file.mmd> [output-name]"
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "Input file not found: $input"
    return 1
  fi

  if [[ "${input:e}" != "mmd" && "${input:e}" != "mermaid" ]]; then
    echo "Expected a .mmd or .mermaid file: $input"
    return 1
  fi

  if ! command -v mmdc >/dev/null 2>&1; then
    echo "mmdc is not installed or not on PATH"
    return 1
  fi

  mkdir -p "$dest_dir" || return 1

  local stem
  if [[ -n "$output_name" ]]; then
    stem="${output_name%.png}"
  else
    stem="${input:t:r}"
  fi

  local output="$dest_dir/$stem.png"
  if (( transparent )); then
    mmdc -i "$input" -o "$output" -b transparent || return 1
  else
    mmdc -i "$input" -o "$output" || return 1
  fi

  echo "Exported to $output"
}

alias mflow='mmdpng'
