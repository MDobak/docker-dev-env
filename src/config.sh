#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

# Volumes mount dir used by default on a Linux
LINUX_MOUNT_DIR=/var/work

# Volumes mount dir used by default on a Mac OS
MACOS_MOUNT_DIR=$HOME/Work/Volumes

# A domain used for the Docker Machines in the Dnsmasq configuration and
# the /etc/hosts file
HOSTNAME_SUFFIX=".loc"

# Verbose level
# 0 - no verbose
# 1 - show full commands output
VERBOSE=0

# Indicates if the help message will be shown
SHOW_HELP=$false

SETUP_VBOX_NETWORK=$true
SETUP_VBOX_NFS_SHARING=$true
SETUP_CONTAINERS_HOSTS=$true
SETUP_CONTAINERS_DNSMASQ=$true
SETUP_HOST_DNSMASQ=$true
