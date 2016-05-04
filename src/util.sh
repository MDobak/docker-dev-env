#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_UTILS_SH=true;

true=0;
false=-1;

# Check if current OS is supported by this script.
check_os_support ()
{
  if [[ ! is_mac && ! is_linux ]]; then
    echo_error "Unsupported operating system! Only Linux and Mac OS are supported!"
    exit 0;
  fi;
}

# Checks if required software is already instaled on current OS.
check_requirements ()
{
  local IS_OK=$true;

  if ! command_exists dnsmasq; then
    echo_error "Fail: dnsmasq is required for this script"
    IS_OK=$false;
  fi;

  if is_mac && ! command_exists docker; then
    echo_error "Fail: docker-machine is required for this script"
    IS_OK=$false;
  fi;

  if is_mac && ! command_exists docker-machine-nfs; then
    echo_error "Fail: docker-machine-nfs is required for this script"
    IS_OK=$false;
  fi;

  if [[ $IS_OK == $false ]]; then
    exit -1;
  fi
}

# Prints error messages
#
# $1 - Error message.
echo_error ()
{
  printf "\033[0;31m$1\033[0m\n"
}

# Prints warning messages
#
# $1 - Warning message.
echo_warn ()
{
  printf "\033[0;33m$1\033[0m\n"
}

# Prints success messages
#
# $1 - Success message.
echo_success ()
{
  printf "\033[0;32m$1\033[0m\n"
}

# Prints fatal error message sand interrupts script execution.
#
# $1 - Success message.
echo_fatal ()
{
  echo
  echo_warn  "--------------------------------------------------------------------------------"
  echo_error "    Script failed!                                                              "
  echo_error "    $1"
  echo_warn  "--------------------------------------------------------------------------------"
  echo

  exit -1;
}

# Prints current step message. After this function you must use one
# of these functions: echo_step_result_ok, echo_step_result_fail or
# echo_step_result_auto to print result.
#
# $1 - Step message.
echo_step ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "    \033[0m[    ] \033[0;32m$1\033[0m\r"
  else
    printf "    \033[0;32m$1\033[0m\n"
  fi
}

# Prints "OK" result for echo_step function.
echo_step_result_ok ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "    \033[0;32m[ OK ]\n"
  fi
}

# Prints "FAIL" result for echo_step function.
echo_step_result_fail ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "    \033[0;31m[FAIL]\n"
  fi
}

# Checks if last command was execute successfuly and if so prints "OK" status,
# in case of an error prints "FAIL" status and interrupts script execution.
echo_step_result_auto ()
{
  if [[ $? == 0 ]]; then
    echo_step_result_ok
  else
    echo_step_result_fail
    echo_fatal "Execute this script again with -v flag to show full logs."
  fi
}

# Prints step name with "INFO" status.
#
# $1 - Message
echo_step_info ()
{
  printf "    \033[0;34m[INFO] \033[0;32m$1\033[0m\n"
}

# Prints step name with "SKIP" status.
#
# $1 - Message
echo_step_skip ()
{
  printf "    \033[0;36m[SKIP] \033[0;32m$1\033[0m\n"
}

# Should be used to execute step commands after echo_step.
# This function executes step (using exec_cmd) and immediately after it ends
# show step status using echo_step_result_auto.
#
# $@ - Command to execute.
exec_step ()
{
  if [[ $VERBOSE == 0 ]]; then
    exec_cmd "$@" &

    local PROC_ID=$!
    local SPINNER=("    " ".   " "..  " "... " "...." " ..." "  .." "   .")
    local SPINNER_IDX=0

    while kill -0 "$PROC_ID" >/dev/null 2>&1; do
      local CURRENT_SPINNER=${SPINNER[${SPINNER_IDX}]}
      SPINNER_IDX=$(( ($SPINNER_IDX+1) % 8 ))

      printf "    \033[0m[$CURRENT_SPINNER]\r"
      sleep 0.5
    done

    wait $PROC_ID
    echo_step_result_auto
  else
    exec_cmd "$@"
    echo_step_result_auto
  fi
}

# Execute command given after that function. If $VERBOSE variables is set to 0
# result of this command will not be shown. When $VERBOSE is set to 1 all
# output will be printed.
#
# $@ - Command to execute.
exec_cmd ()
{
  case $VERBOSE in
    0)
      "$@" &> /dev/null ;;
    1)
      echo "Exec: $@"; "$@" ;;
  esac
}

# Checks if command exists.
#
# $1 - Command to check.
command_exists ()
{
  type "$1" &> /dev/null;
}

# Asks user for ROOT password and store it in ROOT_PASSWORD variable.
sudo_prompt ()
{
  local IS_ROOT=$(sudo_wrapper whoami 2> /dev/null)

  if [[ $IS_ROOT != "root" ]]; then
    echo_warn "    Root is required to run some commands in this script:"
  fi

  until [[ $IS_ROOT == "root" ]]; do
    printf "    Root password: "
    read -s ROOT_PASSWORD
    echo "***"

    IS_ROOT=$(sudo_wrapper whoami 2> /dev/null)
  done

  echo
}

# Runs commands as root using password from ROOT_PASSWORD variable.
#
# $@ - Commands to execute.
sudo_wrapper ()
{
  sudo -k
  echo "$ROOT_PASSWORD" | sudo -S -p "" $@
}

# Checks if current OS is linux.
is_linux ()
{
  if [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    return $true;
  else
    return $false;
  fi;
}

# Checks if current os is mac.
is_mac ()
{
  if [[ "$(uname)" == "Darwin" ]]; then
    return $true;
  else
    return $false;
  fi;
}
