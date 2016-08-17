# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

source src/config.sh
source src/util.sh
source src/dm.sh

source test/functions_stubs.sh

load helpers

CRESET=""
CRED=""
CORANGE=""
CYELLOW=""
CBLUE=""
CLBLUE=""

export PATH="$BATS_TEST_DIRNAME/stub:$BATS_TEST_DIRNAME/tmpstub:$PATH"

@test "checks if docker machine is running" {
  stub is_mac "return 0"
  run dm_is_running test_running

  assert_success
}

@test "checks if docker machine is not running" {
  stub is_mac "return 0"
  run dm_is_running test_not_running

  assert_failure
}

@test "checks if docker machine exists" {
  stub is_mac "return 0"
  run dm_is_exists test

  assert_success
}

@test "checks if docker machine not exists" {
  stub is_mac "return 0"
  run dm_is_exists blahblahblah

  assert_failure
}

@test "try create new docker machine" {
  stub is_mac "return 0"
  run dm_create blahblahblah

  assert_success
}

@test "try create existing docker machine" {
  stub is_mac "return 0"
  run dm_create test

  # Method dm_create should ignore error
  assert_success
}

@test "try start new docker machine" {
  stub is_mac "return 0"
  run dm_start test

  assert_success
}

@test "try start invalid docker machine" {
  stub is_mac "return 0"
  run dm_start blahblahblah

  assert_failure
}

@test "try stop new docker machine" {
  stub is_mac "return 0"
  run dm_stop test

  assert_success
}

@test "try stop invalid docker machine" {
  stub is_mac "return 0"
  run dm_stop blahblahblah

  assert_failure
}

@test "try restart new docker machine" {
  stub is_mac "return 0"
  run dm_restart test

  assert_success
}

@test "try restart invalid docker machine" {
  stub is_mac "return 0"
  run dm_restart blahblahblah

  assert_failure
}

@test "read docker machine host IP" {
  stub is_mac "return 0"
  run dm_host_ip test

  assert_output "192.168.99.1"
}
