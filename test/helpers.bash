# stolen from https://github.com/sstephenson/rbenv/blob/master/test/test_helper.bash

flunk ()
{
  if [ "$#" -eq 0 ]; then cat -
  else echo "$@"
  fi

  return 1
}

assert_success ()
{
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure ()
{
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal ()
{
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output ()
{
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi

  assert_equal "$expected" "$output"
}

assert_line ()
{
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'"
  fi
}

refute_line ()
{
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert ()
{
  if ! "$@"; then
    flunk "failed: $@"
  fi
}

# https://github.com/sstephenson/bats/issues/38
stub ()
{
  [ -d "$BATS_TEST_DIRNAME/stub" ] || mkdir "$BATS_TEST_DIRNAME/stub"
  echo "$2" > "$BATS_TEST_DIRNAME/stub/$1"
  chmod +x "$BATS_TEST_DIRNAME/stub/$1"
}

rm_stubs ()
{
  rm -rf "$BATS_TEST_DIRNAME/stub"
}
