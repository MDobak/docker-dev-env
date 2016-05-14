#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_VBOX_SH=1

# Starts the Docker Machine.
start_docker_machine()
{
   if ! is_mac; then
     return $true;
   fi;

   if [ "$(docker-machine status)" != "Running" ]; then
     echo_step "Starting the Docker Machine"
     exec_step docker-machine start
   fi

   eval "$(docker-machine env default)"
}

# Stops the Docker Machine.
stop_docker_machine()
{
   if ! is_mac; then
     return $true;
   fi;

   if [ "$(docker-machine status)" == "Running" ]; then
     echo_step "Stopping the Docker Machine"
     exec_step docker-machine stop
   fi
}

# Restarts the Docker Machine.
restart_docker_machine()
{
   if ! is_mac; then
     return $true;
   fi;

   if [ "$(docker-machine status)" == "Running" ]; then
     echo_step "Restarting the Docker Machine"
     exec_step docker-machine restart
   fi
}

vbox_host_ip ()
{
  local NETNAME=$(VBoxManage showvminfo default --machinereadable | grep hostonlyadapter | cut -d = -f 2 | xargs)
  VBoxManage list hostonlyifs | grep $NETNAME -A 3 | grep IPAddress | cut -d ':' -f 2 | xargs;
}

# Adds a bridged interface at NIC3 to the Docker Machine.
setup_vbox_network ()
{
   if ! is_mac; then
    return $true;
  fi;

  if ! VBoxManage showvminfo default | grep -q "NIC 3:.*Bridged Interface"; then
    if [ "$(docker-machine status)" == "Running" ]; then
      stop_docker_machine
    fi

    echo_step "Adding a bridged network card to the VirtualBox"
    exec_step VBoxManage modifyvm default --nic3 bridged --bridgeadapter3 en0 --nictype3 82540EM
  else
    echo_step_skip "The VirtualBox network interface is already configured"
  fi
}

# Adds a gateway for the Docker Machine so containers IPs will be accessible
# from the host OS.
setup_vbox_gw ()
{
  if ! is_mac; then
    return $true;
  fi;

  start_docker_machine

  if ! netstat -rn | grep -q "^172.17/24\s*$(docker-machine ip)"; then
    echo_step "Adding a gateway rule for the Docker Machine"

    exec_cmd sudo_wrapper route -n delete 172.17.0.0/24
    exec_cmd sudo_wrapper route add 172.17.0.0/24 $(docker-machine ip)

    echo_step_result_auto
  else
    echo_step_skip "A gateway rule for the Docker Machine already exists"
  fi
}
