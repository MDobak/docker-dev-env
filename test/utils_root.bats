# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

source src/config.sh
source src/util.sh
load helpers

CRESET=""
CRED=""
CORANGE=""
CYELLOW=""
CBLUE=""
CLBLUE=""

export PATH="$BATS_TEST_DIRNAME/stub:$PATH"

@test "root: test sudo_wrapper without verbose" {
  if ! [[ $EUID -eq 0 ]]; then
    skip
  fi

  local VERBOSE=0

  run sudo_wrapper echo "foobar"

  assert_output ""
}

@test "root: test sudo_wrapper with verbose" {
  if ! [[ $EUID -eq 0 ]]; then
    skip
  fi

  local VERBOSE=1

  run sudo_wrapper echo "foobar"

  assert_output "Exec (root) $ echo foobar
foobar"
}

@test "root: test sudo_wrapper without verbose and output redirection" {
  if ! [[ $EUID -eq 0 ]]; then
    skip
  fi

  local VERBOSE=0

  sudo_wrapper "echo \"foobar1\" > $BATS_TEST_DIRNAME/tmp.txt"
  run cat $BATS_TEST_DIRNAME/tmp.txt
  rm $BATS_TEST_DIRNAME/tmp.txt

  assert_output "foobar1"
}

@test "root: test sudo_wrapper with verbose and output redirection" {
  if ! [[ $EUID -eq 0 ]]; then
    skip
  fi

  local VERBOSE=1

  sudo_wrapper "echo \"foobar2\" > $BATS_TEST_DIRNAME/tmp.txt"
  run cat $BATS_TEST_DIRNAME/tmp.txt
  rm $BATS_TEST_DIRNAME/tmp.txt

  assert_output "foobar2"
}
