#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DNSMASQ_SH=1

# Builds dnsmasq configuration file. Configuration file will maps docker
# containers names to thiers IPs.
#
# $1 - Variable name to store output.
build_dnsmasq_config ()
{
  local _HOSTS="";

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
      IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM`;
      _HOSTS="${_HOSTS}address=/$VM.$LOCAL_DOMAIAN/$IP\\\\n";
  done

  eval "$1=\"$_HOSTS\""
}

# Sets configuration for dnsmasq from build_dnsmasq_config on host OS.
setup_host_dnsmasq ()
{
  build_dnsmasq_config HOSTS

  echo_step "Configuring dnsmasq for host"

  if is_mac; then
    sudo_wrapper -s -- <<EOF
      mkdir -p /opt/local/etc/dnsmasq.d
      echo -e "$HOSTS" > /opt/local/etc/dnsmasq.d/docker-hosts.conf
      launchctl load /Library/LaunchDaemons/org.macports.dnsmasq.plist
      launchctl unload /Library/LaunchDaemons/org.macports.dnsmasq.plist
EOF
      dscacheutil -flushcache
  elif is_linux; then
    sudo_wrapper -s -- <<EOF
      echo -e "$HOSTS" > /etc/dnsmasq.d/docker-hosts.conf
      service dnsmasq restart
EOF
  fi

  echo_step_result_ok
}

# Sets configuration for dnsmasq from build_dnsmasq_config on docker containers.
setup_containers_dnsmasq ()
{
  build_dnsmasq_config HOSTS

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
      CONTAINER_CMD="test -d /etc/dnsmasq.d && printf '$HOSTS' >> /etc/dnsmasq.d/docker-hosts.conf"
      DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

      echo_step "Configuring dnsmasq for $VM"
      eval "docker exec $VM $DOCKER_CMD"
      echo_step_result_ok
  done
}
