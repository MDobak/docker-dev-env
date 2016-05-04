#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_VBOX_SH=1

# Starts Docker Machine.
start_docker_machine()
{
   if ! is_mac; then
     return $true;
   fi;

   if [ "$(docker-machine status)" != "Running" ]; then
     echo_step "Starting docker machine"
     exec_step docker-machine start
   fi

   eval "$(docker-machine env default)"
}

# Stops Docker Machine.
stop_docker_machine()
{
   if ! is_mac; then
     return $true;
   fi;

   if [ "$(docker-machine status)" == "Running" ]; then
     echo_step "Stopping docker machine"
     exec_step docker-machine stop
   fi
}

# Adds bridged interface at NIC3 to Docker Machine.
setup_vbox_network ()
{
   if ! is_mac; then
    return $true;
  fi;

  if ! VBoxManage showvminfo default | grep -q "NIC 3:.*Bridged Interface"; then
    if [ "$(docker-machine status)" == "Running" ]; then
      stop_docker_machine
    fi

    echo_step "Adding bridged network card to VitualBox"
    exec_step VBoxManage modifyvm default --nic3 bridged --bridgeadapter3 en0 --nictype3 82540EM
  else
    echo_step_skip "VirtualBox network interface already configured"
  fi
}

# Addeds gateway for Docker Machine so containers IPs will be accessible from
# host.
setup_vbox_gw ()
{
  if ! is_mac; then
    return $true;
  fi;

  start_docker_machine

  if ! netstat -rn | grep -q "^172.17/24\s*$(docker-machine ip)"; then
    echo_step "Adding gateway rule for docker machine"

    exec_cmd sudo_wrapper route -n delete 172.17.0.0/24
    exec_cmd sudo_wrapper route add 172.17.0.0/24 $(docker-machine ip)

    echo_step_result_auto
  else
    echo_step_skip "Gateway rule for docker machine exists"
  fi
}

# Setup NFS sharing in Docker Machine using amazing docker-machine-nfs script
# created by Toni Van de Voorde.
setup_vbox_nfs ()
{
  if ! is_mac; then
    return $true;
  fi;

  start_docker_machine

  echo_step "Configuring NFS sharing"
  exec_step docker-machine-nfs default --shared-folder=$MOUNT_DIR --nfs-config="-alldirs -maproot=0"
}
