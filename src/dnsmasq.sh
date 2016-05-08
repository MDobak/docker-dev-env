#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DNSMASQ_SH=1

# Builds the Dnsmasq configuration file. Configuration file will maps the Docker
# containers names to thiers IPs.
#
# $1 - A variable name to store output.
build_dnsmasq_config ()
{
  local _HOSTS="";

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
      IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM`;
      _HOSTS="${_HOSTS}address=/$VM$HOSTNAME_SUFFIX/$IP\\\\n";
  done

  eval "$1=\$_HOSTS"
}

# Sets configuration for the Dnsmasq from build_dnsmasq_config on a host OS.
setup_host_dnsmasq ()
{
  build_dnsmasq_config HOSTS

  echo_step "Configuring the Dnsmasq for the host OS"

  if is_mac; then
    sudo_wrapper mkdir -p /opt/local/etc/dnsmasq.d

    sudo -s -- <<EOF
      mkdir -p /opt/local/etc/dnsmasq.d
      printf $HOSTS > /opt/local/etc/dnsmasq.d/docker-hosts.conf
      launchctl stop /Library/LaunchDaemons/org.macports.dnsmasq.plist
      launchctl start /Library/LaunchDaemons/org.macports.dnsmasq.plist
EOF
      dscacheutil -flushcache
  elif is_linux; then
    sudo_wrapper -s -- <<EOF
      printf $HOSTS > /etc/dnsmasq.d/docker-hosts.conf
      service dnsmasq restart
EOF
  fi

  echo_step_result_ok
}

# Sets a configuration for the Dnsmasq from the build_dnsmasq_config function
# on the Docker containers.
setup_containers_dnsmasq ()
{
  build_dnsmasq_config HOSTS

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    CONTAINER_CMD="test -d /etc/dnsmasq.d && printf '$HOSTS' >> /etc/dnsmasq.d/docker-hosts.conf"
    DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

    echo_step "Configuring the Dnsmasq for a \"$VM\" machine"
    eval "docker exec $VM $DOCKER_CMD"
    echo_step_result_ok
  done
}
