#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#
# Based on the docker-machine-nfs script written by Toni Van de Voorde:
# https://github.com/adlogix/docker-machine-nfs
#

_NFS_SH=1

# Checks if the NFS shared folder is already mounted on the Docker Machine.
#
# $1 - The Docker Machie name.
# $2 - Path to the mount directory to check.
is_nfs_mounted ()
{
  local DOCKER_MACHINE_NAME=$1
  local MOUNT_DIR=$2
  local HOST_IP=$(vbox_host_ip $DOCKER_MACHINE_NAME)

  if docker-machine ssh $DOCKER_MACHINE_NAME sudo df | grep -q "$HOST_IP:$MOUNT_DIR"; then
    return $true
  else
    return $false
  fi
}

# Configures the NFSD on Mac OS.
#
# $1 - The Docker Machie name.
# $2 - Path to the mount directory.
# $3 - NFS exports options for specifed directory. By default "-alldirs -maproot=0".
setup_macos_nfsd ()
{
  local DOCKER_MACHINE_NAME=$1
  local MOUNT_DIR=$2
  local NFS_CONFIG=$3;
  local IP=$(docker-machine ip $DOCKER_MACHINE_NAME)

  if [[ -z $NFS_CONFIG ]]; then
    NFS_CONFIG="-alldirs -maproot=0"
  fi

  local ESCAPED_MOUNT_DIR=$(echo "$MOUNT_DIR" | sed 's/\//\\\//g')

  echo_step "Configuring NFS sharing on the host OS"

  sudo_wrapper "sed \"/^$ESCAPED_MOUNT_DIR $IP/d\" /etc/exports > /etc/exports"
  sudo_wrapper "printf \"\n$MOUNT_DIR $IP $NFS_CONFIG\n\" >> /etc/exports"

  sudo_wrapper "nfsd restart"
  sudo_wrapper "nfsd checkexports"

  echo_step_result_ok
}

# Mounts NFS shares on the Docker Machine.
#
# $1 - The Docker Machie name.
# $2 - Path to the mount directory.
# $3 - Mount opitions on the Docker Machine. By default "moacl,async".
setup_docker_machine_nfs_mount ()
{
  local DOCKER_MACHINE_NAME=$1
  local MOUNT_DIR=$2
  local MOUNT_OPTIONS=$3;
  local HOST_IP=$(vbox_host_ip $DOCKER_MACHINE_NAME)

  if [[ -z $MOUNT_OPTIONS ]]; then
    MOUNT_OPTIONS="noacl,async"
  fi

  local BOOTLOCAL_FILE='#/bin/bash
sudo umount /Users
sudo mkdir -p '$MOUNT_DIR'
sudo /usr/local/etc/init.d/nfs-client start
sudo mount -t nfs -o '$MOUNT_OPTIONS' '$HOST_IP':'$MOUNT_DIR' '$MOUNT_DIR

  echo_step "Configuring NFS sharing on the Docker Machine"
  exec_step "docker-machine ssh $DOCKER_MACHINE_NAME \"echo '$BOOTLOCAL_FILE' | sudo tee /var/lib/boot2docker/bootlocal.sh && sudo chmod +x /var/lib/boot2docker/bootlocal.sh\""

  if ! is_nfs_mounted $DOCKER_MACHINE_NAME $MOUNT_DIR; then
    restart_docker_machine $DOCKER_MACHINE_NAME
  fi

  if ! is_nfs_mounted $DOCKER_MACHINE_NAME $MOUNT_DIR; then
    echo_fatal "Configuration of NFS sharing failed!\n  Execute this script again with -v flag to enable the verbose mode."
  fi
}
