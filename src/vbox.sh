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
  local STATUS=$(docker-machine status $DOCKER_MACHINE_NAME)

  if [[ $STATUS == "Running" ]]; then
    return $true
  else
    return $false
  fi
}

# Starts the Docker Machine.
#
# $1 - The Docker Machie name.
start_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_mac; then
    return $true;
  fi;

  if ! is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_step "Starting the Docker Machine"
    exec_step docker-machine start $DOCKER_MACHINE_NAME
  fi

  eval "$(docker-machine env $DOCKER_MACHINE_NAME)"
}

# Stops the Docker Machine.
#
# $1 - The Docker Machie name.
stop_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_mac; then
    return $true;
  fi;

  if is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_step "Stopping the Docker Machine"
    exec_step docker-machine stop $DOCKER_MACHINE_NAME
  fi
}

# Restarts the Docker Machine.
#
# $1 - The Docker Machie name.
restart_docker_machine ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_mac; then
    return $true;
  fi;

  if is_docker_machine_running $DOCKER_MACHINE_NAME; then
    echo_step "Restarting the Docker Machine"
    exec_step docker-machine restart $DOCKER_MACHINE_NAME
    eval "$(docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Regenerates The Docker Machine certificates if needed.
#
# $1 - The Docker Machie name.
regenerate_docker_machine_certs ()
{
  local DOCKER_MACHINE_NAME=$1

  if docker-machine env $DOCKER_MACHINE_NAME 2>&1 >/dev/null | grep -q "Error checking TLS connection" > /dev/null; then
    echo_step "Regenerating the Docker Machine certificates"
    exec_step docker-machine regenerate-certs -f $DOCKER_MACHINE_NAME

    eval "$(docker-machine env $DOCKER_MACHINE_NAME)"
  fi
}

# Prints host IP visible inside The Docker Machine.
#
# $1 - The Docker Machie name.
vbox_host_ip ()
{
  local DOCKER_MACHINE_NAME=$1
  local NETNAME=$(VBoxManage showvminfo $DOCKER_MACHINE_NAME --machinereadable | grep hostonlyadapter | cut -d = -f 2 | xargs)

  VBoxManage list hostonlyifs | grep $NETNAME -A 3 | grep IPAddress | cut -d ':' -f 2 | xargs;
}

# Adds a bridged interface at NIC3 to the Docker Machine.
#
# $1 - The Docker Machie name.
setup_vbox_network ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_mac; then
    return $true;
  fi;

  if ! VBoxManage showvminfo $DOCKER_MACHINE_NAME | grep -q "NIC 3:.*Bridged Interface"; then
    if is_docker_machine_running $DOCKER_MACHINE_NAME; then
      stop_docker_machine $DOCKER_MACHINE_NAME
    fi

    echo_step "Adding a bridged network card to the VirtualBox"
    exec_step VBoxManage modifyvm $DOCKER_MACHINE_NAME --nic3 bridged --bridgeadapter3 en0 --nictype3 82540EM
  else
    echo_step_skip "The VirtualBox network interface is already configured"
  fi
}

# Adds a gateway for the Docker Machine so containers IPs will be accessible
# from the host OS.
#
# $1 - The Docker Machie name.
setup_vbox_gw ()
{
  local DOCKER_MACHINE_NAME=$1

  if ! is_mac; then
    return $true;
  fi;

  start_docker_machine $DOCKER_MACHINE_NAME

  if ! netstat -rn | grep -q "^172.17/24\s*$(docker-machine ip $DOCKER_MACHINE_NAME)"; then
    echo_step "Adding a gateway rule for the Docker Machine"

    exec_cmd sudo_wrapper route -n delete 172.17.0.0/24
    exec_cmd sudo_wrapper route add 172.17.0.0/24 $(docker-machine ip $DOCKER_MACHINE_NAME)

    echo_step_result_auto
  else
    echo_step_skip "A gateway rule for the Docker Machine already exists"
  fi
}
