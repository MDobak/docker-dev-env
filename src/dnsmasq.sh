#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DNSMASQ_SH=1

# Builds the Dnsmasq configuration file. The configuration file will maps
# Docker containers names to thiers IPs.
dnsmasq_build_config ()
{
  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    local IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM);

    if [[ -z $(docker inspect --format '{{ .Config.Domainname }}' $VM 2> /dev/null) ]]; then
      local HOSTNAME=$(docker inspect --format '{{ .Config.Hostname }}' $VM);
    else
      local HOSTNAME=$(docker inspect --format '{{ .Config.Hostname }}.{{ .Config.Domainname }}' $VM);
    fi

    _HOSTS="${_HOSTS}address=/$HOSTNAME/$IP\\n";
  done

  echo $_HOSTS
}

# Checks if Dnsmasq is installed on the host OS.
dnsmasq_is_installed_on_host ()
{
  if ! command_exists dnsmasq && ! command_exists $(brew --prefix dnsmasq)/sbin/dnsmasq; then
    return $false;
  fi;

  return $true;
}

# Sets configuration for the Dnsmasq from dnsmasq_build_config on a host OS.
dnsmasq_setup_host ()
{
  if ! dnsmasq_is_installed_on_host; then
    echo_log "The Dnsmasq is not installed on this machine."

    return $true;
  fi

  local HOSTS=$(dnsmasq_build_config)

  if is_mac; then
    if command_exists $(brew --prefix dnsmasq)/sbin/dnsmasq; then
      local CONF_LINE="conf-file=$(brew --prefix)/etc/dnsmasq.d/docker-hosts.conf"

      if ! [[ -d $(brew --prefix)/etc/dnsmasq.d ]]; then
          mkdir $(brew --prefix)/etc/dnsmasq.d
          copy_permissions $(brew --prefix)/etc/dnsmasq.conf $(brew --prefix)/etc/dnsmasq.d
      fi

      if ! [[ -f /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist ]]; then
        cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
      fi

      if ! [[ -f $(brew --prefix)/etc/dnsmasq.conf ]]; then
        cp $(brew --prefix dnsmasq)/dnsmasq.conf.example $(brew --prefix)/etc/dnsmasq.conf
      fi

      if ! fgrep -q "$CONF_LINE" "$(brew --prefix)/etc/dnsmasq.conf"; then
          echo $CONF_LINE >> $(brew --prefix)/etc/dnsmasq.conf
      fi

      printf "$HOSTS" > $(brew --prefix)/etc/dnsmasq.d/docker-hosts.conf
      copy_permissions $(brew --prefix)/etc/dnsmasq.conf $(brew --prefix)/etc/dnsmasq.d/docker-hosts.conf

      launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist > /dev/null
      launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist > /dev/null

      echo_log "The Dnsmasq installed via the Homebrew is configured for the Mac OS."
    elif [[ -f /Library/LaunchDaemons/org.macports.dnsmasq.plist ]]; then
      local CONF_LINE="conf-file=/opt/local/etc/dnsmasq.d/docker-hosts.conf"

      if ! [[ -d /opt/local/etc/dnsmasq.d ]]; then
          mkdir /opt/local/etc/dnsmasq.d
          copy_permissions /opt/local/etc /opt/local/etc/dnsmasq.d
      fi

      if ! fgrep -q "$CONF_LINE" "/opt/local/etc/dnsmasq.conf"; then
          echo $CONF_LINE >> /opt/local/etc/dnsmasq.conf
      fi

      printf "$HOSTS" > /opt/local/etc/dnsmasq.d/docker-hosts.conf
      launchctl unload /Library/LaunchDaemons/org.macports.dnsmasq.plist > /dev/null
      launchctl load /Library/LaunchDaemons/org.macports.dnsmasq.plist > /dev/null

      echo_log "The Dnsmasq installed via the MacPorts is configured for the Mac OS."
    fi

    dscacheutil -flushcache > /dev/null
    killall -HUP mDNSResponder > /dev/null
  elif is_linux; then
    local CONF_LINE="conf-file=/etc/dnsmasq.d/docker-hosts.conf"

    if ! fgrep -q "$CONF_LINE" "/etc/dnsmasq.conf"; then
        echo $CONF_LINE >> /etc/dnsmasq.conf
    fi

    printf "$HOSTS" | tee /etc/dnsmasq.d/docker-hosts.conf
    service dnsmasq restart > /dev/null

    echo_log "The Dnsmasq is configured for the Linux OS."
  fi

  return $true
}

# Sets a configuration for the Dnsmasq from the dnsmasq_build_config function
# on the Docker containers.
#
# $1 - Setup only containers created by this script. $true/$false.
dnsmasq_setup_containers ()
{
  local SETUP_ONLY_DEV_ENV_CONTAINERS=$1

  local HOSTS=$(dnsmasq_build_config)

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    if [[ $SETUP_ONLY_DEV_ENV_CONTAINERS == $true ]] && ! docker_is_dev_env_container $VM; then
      continue;
    fi

    docker exec $VM /bin/sh -c \
      "test -d /etc/dnsmasq.d && printf '$HOSTS' | tee /etc/dnsmasq.d/docker-hosts.conf" > /dev/null
  done
}

# Sets a configuration for the Dnsmasq in a dnsmasq-server container.
dnsmasq_setup_server ()
{
  local HOSTS=$(dnsmasq_build_config)

  docker exec dnsmasq-server /bin/sh -c \
    "grep -q '^conf-dir=/etc/dnsmasq.d$' /etc/dnsmasq.conf || echo 'conf-dir=/etc/dnsmasq.d' > /etc/dnsmasq.conf"

  docker exec dnsmasq-server mkdir -p /etc/dnsmasq.d
  docker restart dnsmasq-server > /dev/null

  docker exec dnsmasq-server /bin/sh -c \
    "test -d /etc/dnsmasq.d && printf '$HOSTS' | tee /etc/dnsmasq.d/docker-hosts.conf" > /dev/null
}

# Changes a DNS IP in /etc/resolv.conf in all containers to a dnsmasq-server
# container IP.
#
# $1 - Setup only containers created by this script. $true/$false.
dnsmasq_setup_containers_resolv ()
{
  local SETUP_ONLY_DEV_ENV_CONTAINERS=$1
  local DNSMASQ_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' dnsmasq-server)

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    if [[ $SETUP_ONLY_DEV_ENV_CONTAINERS == $true ]] && ! docker_is_dev_env_container $VM; then
      continue;
    fi

    if [[ $VM == 'dnsmasq-server' ]]; then
      continue
    fi

    echo_log "Configuring the /etc/resolv.conf file for the \"$VM\" container"
    docker exec $VM /bin/sh -c "printf 'nameserver $DNSMASQ_IP' | tee /etc/resolv.conf" > /dev/null
  done
}
