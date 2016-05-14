#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_NFS_SH=1

# Checks if the NFS shared folder is already mounted on the Docker Machine.
#
# $1 - Path to the mount directory to check
is_nfs_mounted ()
{
  local MOUNT_DIR=$1
  local HOST_IP=$(vbox_host_ip)

  if [[ -z $MOUNT_DIR ]]; then
    MOUNT_DIR="/Users"
  fi

  if docker-machine ssh default sudo df | grep -q "$HOST_IP:$MOUNT_DIR"; then
    return $true
  else
    return $false
  fi
}

# Configures the NFSD on Mac OS.
#
# $1 - Path to the mount directory
# $2 - NFS exports options for specifed directory
setup_macos_nfsd ()
{
  local MOUNT_DIR=$1
  local NFS_CONFIG=$2;
  local IP=$(docker-machine ip)

  if [[ -z $NFS_CONFIG ]]; then
    NFS_CONFIG="-alldirs -maproot=0"
  fi

  local ESCAPED_MOUNT_DIR=$(echo "$MOUNT_DIR" | sed 's/\//\\\//g')

  echo_step "Configuring NFS sharing on the host OS"

  sudo_wrapper '
    sed "/^'$ESCAPED_MOUNT_DIR' '$IP'/d" /etc/exports > /etc/exports
    printf "\n'$MOUNT_DIR' '$IP' '$NFS_CONFIG'\n" >> /etc/exports
  '

  sudo_wrapper nfsd restart
  sudo_wrapper nfsd checkexports

  echo_step_result_ok
}

# Mounts NFS shares on the Docker Machine.
#
# $1 - Path to the mount directory.
# $2 - Mount opitions on the Docker Machine. By default "moacl,async".
setup_docker_machine_nfs_mount ()
{
  local MOUNT_DIR=$1
  local MOUNT_OPTIONS=$2;
  local HOST_IP=$(vbox_host_ip)

  if [[ -z $MOUNT_OPTIONS ]]; then
    MOUNT_OPTIONS="noacl,async"
  fi

  local BOOT2LOCAL_FILE='#/bin/bash
sudo umount /Users
sudo mkdir -p '$MOUNT_DIR'
sudo /usr/local/etc/init.d/nfs-client start
sudo mount -t nfs -o '$MOUNT_OPTIONS' '$HOST_IP':'$MOUNT_DIR' '$MOUNT_DIR

  echo_step "Configuring the NFS sharing on the Docker Machine"
  exec_cmd docker-machine ssh default "echo '$BOOT2LOCAL_FILE' | sudo tee /var/lib/boot2docker/bootlocal.sh && sudo chmod +x /var/lib/boot2docker/bootlocal.sh"

  if ! is_nfs_mounted $MOUNT_DIR; then
    exec_cmd docker-machine restart
  fi

  if is_nfs_mounted $MOUNT_DIR; then
    echo_step_result_ok
  else
    echo_step_result_fail
  fi
}
