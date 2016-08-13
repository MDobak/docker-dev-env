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

@test "checks if command exists" {
  run command_exists grep

  assert_success
}

@test "checks if command not exists" {
  run command_exists foobarblah

  assert_failure
}

@test "checks if Linux is supported" {
  stub is_mac "return -1"
  stub is_linux "return 0"

  run check_os_support

  assert_success
}

@test "checks if Mac OS is supported" {
  stub is_mac "return 0"
  stub is_linux "return -1"

  run check_os_support

  assert_success
}

@test "checks if Windows is not supported" {
  stub is_mac "return -1"
  stub is_linux "return -1"

  echo $status

  assert_failure
}

@test "checks if current OS is Linux" {
  stub uname "echo Linux"

  run is_linux

  assert_success
}

@test "checks if current OS is not Linux" {
  stub uname "echo Darwin"

  run is_linux

  assert_failure
}

@test "checks if current OS is Mac OS" {
  stub uname "echo Darwin"

  run is_mac

  assert_success
}

@test "checks if current OS is not Mac OS" {
  stub uname "echo Linux"

  run is_mac

  assert_failure
}
