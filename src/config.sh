#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

# Volumes mount dir used by default on Linux
LINUX_MOUNT_DIR=/var/work

# Volumes mount dir used by default on MacOS
MACOS_MOUNT_DIR=$HOME/Work/Volumes

# Domain used for Docker machines in dnsmasq configuration and /etc/hosts
LOCAL_DOMAIAN="loc"

# Verbode level
# 0 - no verbose
# 1 - show full commands output
VERBOSE=0

SETUP_VBOX_NETWORK=$true
SETUP_VBOX_NFS_SHARING=$true
SETUP_CONTAINERS_HOSTS=$true
SETUP_CONTAINERS_DNSMASQ=$true
SETUP_HOST_DNSMASQ=$true
