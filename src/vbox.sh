#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_VBOX_SH=1

# Checks if the Docker Macine is running.
#
# $1 - The Docker Machie name.
is_docker_machine_running ()
{
  local DOCKER_MACHINE_NAME=$1
  local STATUS=$(run_as_user docker-machine status $DOCKER_MACHINE_NAME)

  if [[ $STATUS == "Running" ]]; then
    return $true
  else
    return $false
  fi
}

# Checks if the Docker Machine exists
#
# $1 - The Docker Machie name.
is_docker_machine_exists ()
{
  local DOCKER_MACHINE_NAME=$1

  if run_as_user docker-machine ls -q | fgrep -q $DOCKER_MACHINE_NAME; then
    return $true;
  else
    return $false;
  fi
}

# Creates the Docker Machine.
#
# $1 - The Docker Machie name.
create_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if is_mac && ! is_docker_machine_exists $DOCKER_MACHINE_NAME; then
    verbose run_as_user docker-machine create -d virtualbox $DOCKER_MACHINE_NAME
  fi

  eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
}

# Starts the Docker Machine.
#
# $1 - The Docker Machie name.
start_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_log "Starting the Docker Machine"
    run_as_user docker-machine start $DOCKER_MACHINE_NAME > /dev/null
  fi

  eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
}

# Stops the Docker Machine.
#
# $1 - The Docker Machie name.
stop_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_log "Stopping the Docker Machine"
    run_as_user docker-machine stop $DOCKER_MACHINE_NAME > /dev/null
  fi
}

# Restarts the Docker Machine.
#
# $1 - The Docker Machie name.
restart_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_log "Restarting the Docker Machine"
    run_as_user docker-machine restart $DOCKER_MACHINE_NAME > /dev/null
    eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Regenerates The Docker Machine certificates if needed.
#
# $1 - The Docker Machie name.
regenerate_docker_machine_certs ()
{
  local DOCKER_MACHINE_NAME=$1

  start_docker_machine $1

  if run_as_user docker-machine env $DOCKER_MACHINE_NAME 2>&1 >/dev/null | grep -q "Error checking TLS connection" > /dev/null; then
    run_as_user docker-machine regenerate-certs -f $DOCKER_MACHINE_NAME > /dev/null

    eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Prints host IP visible inside The Docker Machine.
#
# $1 - The Docker Machie name.
vbox_host_ip ()
{
  local DOCKER_MACHINE_NAME=$1
  local NETNAME=$(run_as_user VBoxManage showvminfo $DOCKER_MACHINE_NAME --machinereadable | grep hostonlyadapter | cut -d = -f 2 | xargs)

  run_as_user VBoxManage list hostonlyifs | grep $NETNAME -A 3 | grep IPAddress | cut -d ':' -f 2 | xargs;
}

# Adds a bridged interface at NIC3 to the Docker Machine.
#
# $1 - The Docker Machie name.
setup_vbox_network ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! run_as_user VBoxManage showvminfo $DOCKER_MACHINE_NAME | grep -q "NIC 3:.*Bridged Interface"; then
    if is_docker_machine_running $DOCKER_MACHINE_NAME; then
      stop_docker_machine $DOCKER_MACHINE_NAME
    fi

    run_as_user VBoxManage modifyvm $DOCKER_MACHINE_NAME --nic3 bridged --bridgeadapter3 en0 --nictype3 82540EM
  fi
}

# Adds a gateway for the Docker Machine so containers IPs will be accessible
# from the host OS.
#
# $1 - The Docker Machie name.
setup_vbox_gw ()
{
  local DOCKER_MACHINE_NAME=$1

  start_docker_machine $DOCKER_MACHINE_NAME

  if ! netstat -rn | grep -q "^172.17/24\s*$(run_as_user docker-machine ip $DOCKER_MACHINE_NAME)"; then
    route -n delete 172.17.0.0/24 > /dev/null
    route add 172.17.0.0/24 $(run_as_user docker-machine ip $DOCKER_MACHINE_NAME) > /dev/null
  fi
}
