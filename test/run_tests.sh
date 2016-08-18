#!/bin/bash
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

set -e

sudo printf ""

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$CURRENT_DIR/.."

bats "$BASE_DIR/test"
"$BASE_DIR/test/integration/example-php5.sh"
