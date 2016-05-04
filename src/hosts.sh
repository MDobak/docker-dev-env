#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_HOSTS_SH=1

# Builds /etc/hosts configuration file. Configuration file will maps docker
# containers names to thiers IPs.
#
# $1 - Variable name to store output.
build_host_file ()
{
  local _HOSTS="";

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
      IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM`;
      _HOSTS="$_HOSTS$IP $VM.$LOCAL_DOMAIAN\n";
  done

  eval "$1=\"$_HOSTS\""
}

# Append configuration for /etc/hosts from build_host_file on host OS.
setup_containers_host_files ()
{
  build_host_file HOSTS

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
      CONTAINER_CMD="printf '$HOSTS' >> /etc/hosts; eval 'sort -u /etc/hosts' > /etc/hosts_tmp; cat /etc/hosts_tmp > /etc/hosts"
      DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

      echo_step "Configuring /etc/hosts for $VM"
      eval "docker exec $VM $DOCKER_CMD"
      echo_step_result_ok
  done
}
