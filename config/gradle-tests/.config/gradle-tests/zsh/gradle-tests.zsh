export GRADLE_TESTS_HOME="$HOME/.config/gradle-tests"
export GRADLE_TESTS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/gradle-tests"

local gradle_tests_bin_dir="$GRADLE_TESTS_HOME/bin"
if [[ -d "$gradle_tests_bin_dir" && ":$PATH:" != *":$gradle_tests_bin_dir:"* ]]; then
  path=("$gradle_tests_bin_dir" $path)
fi

_gradle_tests() {
  if (( CURRENT == 2 )); then
    compadd -- failed --help
  elif [[ "${words[2]-}" == failed ]]; then
    compadd -- --verbose --help
  fi
}

compdef _gradle_tests gradle-tests
