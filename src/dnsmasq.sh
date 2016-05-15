#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DNSMASQ_SH=1

# Builds the Dnsmasq configuration file. The configuration file will maps
# Docker containers names to thiers IPs.
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
  if ! command_exists dnsmasq; then
    echo_step_skip "The Dnsmasq configuration was skipped beacuse is not installed on host OS"
    return
  fi;

  build_dnsmasq_config HOSTS

  echo_step "Configuring the Dnsmasq for the host OS"

  if is_mac; then
    if [[ -f /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist ]]; then
      sudo_wrapper -s -- <<EOF
        mkdir -p $(brew --prefix dnsmasq)/etc/dnsmasq.d
        printf $HOSTS > $(brew --prefix dnsmasq)/etc/dnsmasq.d/docker-hosts.conf
        launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
        launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
EOF
    elif [[ -f /Library/LaunchDaemons/org.macports.dnsmasq.plist ]]; then
      sudo_wrapper -s -- <<EOF
        mkdir -p /opt/local/etc/dnsmasq.d
        printf $HOSTS > /opt/local/etc/dnsmasq.d/docker-hosts.conf
        launchctl unload /Library/LaunchDaemons/org.macports.dnsmasq.plist
        launchctl load /Library/LaunchDaemons/org.macports.dnsmasq.plist
EOF
    fi

      dscacheutil -flushcache
      sudo_wrapper killall -HUP mDNSResponder
  elif is_linux; then
    sudo_wrapper -s -- <<EOF
      grep -q "^conf-dir=/etc/dnsmasq.d$" /etc/dnsmasq.conf || echo "conf-dir=/etc/dnsmasq.d" >> /etc/dnsmasq.conf
      printf $HOSTS > /etc/dnsmasq.d/docker-hosts.conf
      service dnsmasq restart
EOF
  fi

  echo_step_result_ok
}

# Sets a configuration for the Dnsmasq from the build_dnsmasq_config function
# on the Docker containers.
#
# $1 - Setup only containers created by this script. $true/$false.
setup_containers_dnsmasq ()
{
  local SETUP_ONLY_DEV_ENV_CONTAINERS=$1

  build_dnsmasq_config HOSTS

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    if [[ $SETUP_ONLY_DEV_ENV_CONTAINERS == $true ]] && ! is_dev_env_container $VM; then
      continue;
    fi

    local CONTAINER_CMD="test -d /etc/dnsmasq.d && printf '$HOSTS' >> /etc/dnsmasq.d/docker-hosts.conf"
    local DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

    echo_step "Configuring the Dnsmasq for a \"$VM\" machine"
    eval "docker exec $VM $DOCKER_CMD"
    echo_step_result_ok
  done
}

# Sets a configuration for the Dnsmasq in a dnsmasq-server container.
setup_dnsmasq_config ()
{
  build_dnsmasq_config HOSTS

  local CONTAINER_CMD="test -d /etc/dnsmasq.d && printf '$HOSTS' >> /etc/dnsmasq.d/docker-hosts.conf"
  local DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

  echo_step "Configuring the dnsmasq-server"
  exec_cmd docker exec dnsmasq-server /bin/sh -c \
    "grep -q \"^conf-dir=/etc/dnsmasq.d$\" /etc/dnsmasq.conf || echo \"conf-dir=/etc/dnsmasq.d\" >> /etc/dnsmasq.conf"
  exec_cmd docker exec dnsmasq-server mkdir -p /etc/dnsmasq.d
  exec_cmd docker stop dnsmasq-server
  exec_cmd docker start dnsmasq-server
  eval "docker exec dnsmasq-server $DOCKER_CMD"
  echo_step_result_ok
}

# Changes a DNS IP in /etc/resolv.conf in all containers to a dnsmasq-server
# container IP.
#
# $1 - Setup only containers created by this script. $true/$false.
setup_dnsmasq_resolv ()
{
  local SETUP_ONLY_DEV_ENV_CONTAINERS=$1
  local DNSMASQ_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' dnsmasq-server)

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    if [[ $SETUP_ONLY_DEV_ENV_CONTAINERS == $true ]] && ! is_dev_env_container $VM; then
      continue;
    fi

    if [[ $VM == 'dnsmasq-server' ]]; then
      continue
    fi

    local CONTAINER_CMD="printf 'nameserver $DNSMASQ_IP' > /etc/resolv.conf"
    local DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

    echo_step "Configuring the /etc/resolv.conf file for the \"$VM\" machine"
    exec_cmd eval "docker exec $VM $DOCKER_CMD"
    echo_step_result_ok
  done
}
