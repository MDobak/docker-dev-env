#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

# Volumes mount dir used by default on a Linux
LINUX_MOUNT_DIR=/var/work

# Volumes mount dir used by default on a Mac OS
MACOS_MOUNT_DIR=$HOME/Work/Volumes

# Docker Machine name
DOCKER_MACHINE_NAME=default

# Verbose level
# 0 - no verbose
# 1 - show full commands output
VERBOSE=0

# Indicates if the help message will be shown
SHOW_HELP=$false

SETUP_ONLY_DEV_ENV_CONTAINERS=$true
SETUP_VBOX_NETWORK=$true
SETUP_VBOX_NFS_SHARING=$true
SETUP_CONTAINERS_HOSTS=$true
SETUP_CONTAINERS_DNSMASQ=$false
SETUP_HOST_HOSTS=$false
SETUP_HOST_DNSMASQ=$true

# Colors
CRESET="\033[0m"
CRED="\033[0;31m"
CORANGE="\033[0;33m"
CYELLOW="\033[0;32m"
CBLUE="\033[0;34m"
CLBLUE="\033[0;36m"
