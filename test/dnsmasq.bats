# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

source src/config.sh
source src/util.sh
source src/dnsmasq.sh

source test/functions_stubs.sh

load helpers

CRESET=""
CRED=""
CORANGE=""
CYELLOW=""
CBLUE=""
CLBLUE=""

export PATH="$BATS_TEST_DIRNAME/stub:$BATS_TEST_DIRNAME/tmpstub:$PATH"

@test "test buldin dnsmasq config" {
  run dnsmasq_build_config

  assert_output "address=/registry/172.17.0.1\naddress=/example-mysql/172.17.0.2\naddress=/foobar1.local/172.17.0.3\naddress=/foobar2.local/172.17.0.4\naddress=/dnsmasq-server/172.17.0.5\n"
}
