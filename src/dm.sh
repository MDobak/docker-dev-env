#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DM_SH=1

# Checks if the Docker Macine is running.
#
# $1 - The Docker Machie name.
dm_is_running ()
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
dm_is_exists ()
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
dm_create ()
{
  local DOCKER_MACHINE_NAME=$1

  if is_mac && ! dm_is_exists $DOCKER_MACHINE_NAME; then
    err_catch verbose run_as_user docker-machine create -d virtualbox $DOCKER_MACHINE_NAME
  fi

  eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
}

# Starts the Docker Machine.
#
# $1 - The Docker Machie name.
dm_start ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! dm_is_running $DOCKER_MACHINE_NAME; then
    echo_log "Starting the Docker Machine"
    run_as_user docker-machine start $DOCKER_MACHINE_NAME > /dev/null
  fi

  eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
}

# Stops the Docker Machine.
#
# $1 - The Docker Machie name.
dm_stop ()
{
  local DOCKER_MACHINE_NAME=$1

  if dm_is_running $DOCKER_MACHINE_NAME; then
    echo_log "Stopping the Docker Machine"
    run_as_user docker-machine stop $DOCKER_MACHINE_NAME > /dev/null
  fi
}

# Restarts the Docker Machine.
#
# $1 - The Docker Machie name.
dm_restart ()
{
  local DOCKER_MACHINE_NAME=$1

  if dm_is_running $DOCKER_MACHINE_NAME; then
    echo_log "Restarting the Docker Machine"
    run_as_user docker-machine restart $DOCKER_MACHINE_NAME > /dev/null
    eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Regenerates The Docker Machine certificates if needed.
#
# $1 - The Docker Machie name.
dm_regenerate_certs ()
{
  local DOCKER_MACHINE_NAME=$1

  dm_start $1

  if run_as_user docker-machine env $DOCKER_MACHINE_NAME 2>&1 >/dev/null | grep -q "Error checking TLS connection" > /dev/null; then
    run_as_user docker-machine regenerate-certs -f $DOCKER_MACHINE_NAME > /dev/null

    eval "$(run_as_user docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Prints host IP visible inside The Docker Machine.
#
# $1 - The Docker Machie name.
dm_host_ip ()
{
  local DOCKER_MACHINE_NAME=$1
  local NETNAME=$(run_as_user VBoxManage showvminfo $DOCKER_MACHINE_NAME --machinereadable | grep hostonlyadapter | cut -d = -f 2 | xargs)

  err_catch run_as_user VBoxManage list hostonlyifs | grep $NETNAME -A 3 | grep IPAddress | cut -d ':' -f 2 | xargs;
}

# Adds a bridged interface at NIC3 to the Docker Machine.
#
# $1 - The Docker Machie name.
dm_setup_vbox_network ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! err_catch run_as_user VBoxManage showvminfo $DOCKER_MACHINE_NAME | grep -q "NIC 3:.*Bridged Interface"; then
    if dm_is_running $DOCKER_MACHINE_NAME; then
      dm_stop $DOCKER_MACHINE_NAME
    fi

    err_catch run_as_user VBoxManage modifyvm $DOCKER_MACHINE_NAME --nic3 bridged --bridgeadapter3 en0 --nictype3 82540EM
  fi
}

# Adds a gateway for the Docker Machine so containers IPs will be accessible
# from the host OS.
#
# $1 - The Docker Machie name.
dm_setup_vbox_gw ()
{
  local DOCKER_MACHINE_NAME=$1

  dm_start $DOCKER_MACHINE_NAME

  if ! netstat -rn | grep -q "^172.17/24\s*$(run_as_user docker-machine ip $DOCKER_MACHINE_NAME)"; then
    err_catch route -n delete 172.17.0.0/24 > /dev/null
    err_catch route add 172.17.0.0/24 $(run_as_user docker-machine ip $DOCKER_MACHINE_NAME) > /dev/null
  fi
}
