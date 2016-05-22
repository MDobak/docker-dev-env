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
    local IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM);

    if [[ -z $(docker inspect --format '{{ .Config.Domainname }}' $VM 2> /dev/null) ]]; then
      local HOSTNAME=$(docker inspect --format '{{ .Config.Hostname }}' $VM);
    else
      local HOSTNAME=$(docker inspect --format '{{ .Config.Hostname }}.{{ .Config.Domainname }}' $VM);
    fi

    _HOSTS="${_HOSTS}address=/$HOSTNAME/$IP\\n";
  done

  eval "$1=\$_HOSTS"
}

# Sets configuration for the Dnsmasq from build_dnsmasq_config on a host OS.
setup_host_dnsmasq ()
{
  if ! command_exists dnsmasq && ! command_exists $(brew --prefix dnsmasq)/sbin/dnsmasq; then
    echo_step_skip "Configuring the Dnsmasq for the host OS (the Dnsmasq is not installed on the host OS!)"
    return
  fi;

  build_dnsmasq_config HOSTS

  echo_step "Configuring the Dnsmasq for the host OS"

  if is_mac; then
    if command_exists $(brew --prefix dnsmasq)/sbin/dnsmasq; then
      local CONF_LINE="conf-file=$(brew --prefix)/etc/dnsmasq.d/docker-hosts.conf"

      exec_cmd mkdir -p $(brew --prefix)/etc
      exec_cmd mkdir -p $(brew --prefix)/etc/dnsmasq.d

      if ! [[ -f /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist ]]; then
        exec_cmd cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
      fi

      if ! [[ -f $(brew --prefix)/etc/dnsmasq.conf ]]; then
        exec_cmd cp $(brew --prefix dnsmasq)/dnsmasq.conf.example $(brew --prefix)/etc/dnsmasq.conf
      fi

      if ! fgrep -q "$CONF_LINE" "$(brew --prefix)/etc/dnsmasq.conf"; then
          exec_cmd "echo $CONF_LINE >> $(brew --prefix)/etc/dnsmasq.conf"
      fi

      exec_cmd "printf \"$HOSTS\" > $(brew --prefix)/etc/dnsmasq.d/docker-hosts.conf"
      sudo_wrapper "launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
      sudo_wrapper "launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
    elif [[ -f /Library/LaunchDaemons/org.macports.dnsmasq.plist ]]; then
      local CONF_LINE="conf-file=/opt/local/etc/dnsmasq.d/docker-hosts.conf"

      sudo_wrapper "mkdir -p /opt/local/etc/dnsmasq.d"

      if ! fgrep -q "$CONF_LINE" "/opt/local/etc/dnsmasq.conf"; then
          exec_cmd "echo $CONF_LINE >> /opt/local/etc/dnsmasq.conf"
      fi

      sudo_wrapper "printf \"$HOSTS\" > /opt/local/etc/dnsmasq.d/docker-hosts.conf"
      sudo_wrapper "launchctl unload /Library/LaunchDaemons/org.macports.dnsmasq.plist"
      sudo_wrapper "launchctl load /Library/LaunchDaemons/org.macports.dnsmasq.plist"
    fi

    dscacheutil -flushcache
    sudo_wrapper "killall -HUP mDNSResponder"
  elif is_linux; then
    local CONF_LINE="conf-file=/etc/dnsmasq.d/docker-hosts.conf"

    if ! fgrep -q "$CONF_LINE" "/etc/dnsmasq.conf"; then
        exec_cmd "echo $CONF_LINE >> /etc/dnsmasq.conf"
    fi

    sudo_wrapper "printf \"$HOSTS\" > /etc/dnsmasq.d/docker-hosts.conf"
    sudo_wrapper "service dnsmasq restart"
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

    echo_step "Configuring the Dnsmasq for the \"$VM\" container"
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

    echo_step "Configuring the /etc/resolv.conf file for the \"$VM\" container"
    exec_cmd eval "docker exec $VM $DOCKER_CMD"
    echo_step_result_ok
  done
}
