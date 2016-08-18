#!/bin/bash
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

set -e

sudo printf ""

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$CURRENT_DIR/../.."

echo "--------------------------------------------------------------------------------"
echo "  1) Removing previous test image"
echo "--------------------------------------------------------------------------------"
docker-machine rm integration-test -y || true

echo "OK!"

echo "--------------------------------------------------------------------------------"
echo "  2) Creating new test image"
echo "--------------------------------------------------------------------------------"

sudo $BASE_DIR/bin/docker-dev-env -d integration-test $BASE_DIR/images/example-php5 -v
eval "$(docker-machine env integration-test)"
docker exec example-php5 bash -c "apt-get install host -y"

PHP5_SERVER_IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" example-php5)
DNSMASQ_SERVER_IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" dnsmasq-server)

echo "--------------------------------------------------------------------------------"
echo "  3) Check Dnsmasq-server from host"
echo "--------------------------------------------------------------------------------"

RESOLVED_IP=$(dig +short example-php5.loc @$DNSMASQ_SERVER_IP)

if ! [[ $RESOLVED_IP == $PHP5_SERVER_IP ]]; then
  echo "Error! Dnsmasq-server returned invalid IP for example-php5 container!"
  exit -1
else
  echo "OK!"
fi

echo "--------------------------------------------------------------------------------"
echo "  4) Check Dnsmasq-server from container"
echo "--------------------------------------------------------------------------------"

RESOLVED_IP=$(docker exec example-php5 bash -c "host subdomains.should.also.work.example-php5.loc | awk '/has address/ { print \$4 ; exit }'")

if ! [[ $RESOLVED_IP == $PHP5_SERVER_IP ]]; then
  echo "Error! Dnsmasq-server returned invalid IP for example-php5 container!"
  exit -1
else
  echo "OK!"
fi

echo "--------------------------------------------------------------------------------"
echo "  5) Check connection to container from host"
echo "--------------------------------------------------------------------------------"

docker exec example-php5 bash -c "echo 'Hello World' > /var/www/html/index.html"

if ! [[ "$(curl -s -L $PHP5_SERVER_IP)" == "Hello World" ]]; then
  echo "Error! Unable to connect to example-php5 container!"
  exit -1
else
  echo "OK!"
fi

echo
echo "Test passed successfully!"
echo
