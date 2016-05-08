#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_HOSTS_SH=1

# Builds the /etc/hosts configuration file. The configuration file will maps the
# Docker containers names to thiers IPs.
#
# $1 - A variable name to store output.
build_host_file ()
{
  local _HOSTS="";

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $VM`;
    _HOSTS="$_HOSTS$IP $VM$HOSTNAME_SUFFIX # Generated by docker-dev-env\n";
  done

  eval "$1=\"$_HOSTS\""
}

# Append a configuration for the /etc/hosts file from the build_host_file
# function on the host OS.
setup_containers_host_files ()
{
  build_host_file HOSTS

  for VM in `docker ps|tail -n +2|awk '{print $NF}'`; do
    CONTAINER_CMD="printf '$HOSTS' >> /etc/hosts"
    DOCKER_CMD="/bin/sh -c \"$CONTAINER_CMD\""

    echo_step "Configuring the /etc/hosts file for a \"$VM\" machine"
    exec_cmd docker exec $VM /bin/sh -c "sed '/# Generated by docker-dev-env/d' /etc/hosts > /etc/hosts_tmp; cat /etc/hosts_tmp > /etc/hosts"
    exec_cmd eval "docker exec $VM $DOCKER_CMD"
    echo_step_result_ok
  done
}
