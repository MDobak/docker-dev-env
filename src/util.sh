#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_UTILS_SH=true;

true=0
false=-1

# Check if current OS is supported by this script.
check_os_support ()
{
  if [[ ! is_mac && ! is_linux ]]; then
    echo_error "Unsupported operating system! Only the Linux and Mac OS are supported!"
    exit 0;
  fi;
}

# Check if required software is already instaled on current OS.
check_requirements ()
{
  local IS_OK=$true;

  if is_mac && ! command_exists docker-machine; then
    echo_error "Fail: The Docker Machine is required for this script"
    IS_OK=$false;
  fi;

  if ! command_exists docker; then
    echo_error "Fail: The Docker is required for this script"
    IS_OK=$false;
  fi;

  if [[ $IS_OK == $false ]]; then
    exit -1;
  fi
}

# Prints an error messages
#
# $1 - An error message.
echo_error ()
{
  printf "\033[0;31m$1\033[0m\n"
}

# Prints a warning messages
#
# $1 - A warning message.
echo_warn ()
{
  printf "\033[0;33m$1\033[0m\n"
}

# Prints a success messages
#
# $1 - A success message.
echo_success ()
{
  printf "\033[0;32m$1\033[0m\n"
}

# Prints a fatal error message and interrupts the script execution.
#
# $1 - A success message.
echo_fatal ()
{
  echo
  echo_warn  "--------------------------------------------------------------------------------"
  echo_error "  Script failed!                                                              "
  echo_error "  $1"
  echo_warn  "--------------------------------------------------------------------------------"
  echo

  exit -1;
}

# Prints current step message. After this function you must use one
# of these functions: echo_step_result_ok, echo_step_result_fail or
# echo_step_result_auto to print the result.
#
# $1 - Step message.
echo_step ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "\033[0m[    ] \033[0;32m$1\033[0m\r"
  else
    printf "\033[0;32m$1\033[0m\n"
  fi
}

# Prints the "OK" result for echo_step function.
echo_step_result_ok ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "\033[0;32m[ OK ]\n"
  fi
}

# Prints the "FAIL" result for echo_step function.
echo_step_result_fail ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "\033[0;31m[FAIL]\n"
  fi
}

# Check if last command was executed successfuly and if so it prints the "OK"
# status, in case of an error it prints the "FAIL" status and interrupts the
# script execution.
echo_step_result_auto ()
{
  if [[ $? == 0 ]]; then
    echo_step_result_ok
  else
    echo_step_result_fail
    echo_fatal "Execute this script again with -v flag to enable the verbose mode."
  fi
}

# Prints a step name withthe  "INFO" status.
#
# $1 - A message.
echo_step_info ()
{
  printf "\033[0;34m[INFO] \033[0;32m$1\033[0m\n"
}

# Prints a step name with the "SKIP" status.
#
# $1 - A message.
echo_step_skip ()
{
  printf "\033[0;36m[SKIP] \033[0;32m$1\033[0m\n"
}

# Should be used to execute step commands after a echo_step.
# This function executes a step (using the exec_cmd function) and immediately
# after it shows the step status using the echo_step_result_auto.
#
# $@ - A command to execute.
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

      printf "\033[0m[$CURRENT_SPINNER]\r"
      sleep 0.5
    done

    wait $PROC_ID
    echo_step_result_auto
  else
    exec_cmd "$@"
    echo_step_result_auto
  fi
}

# Execute the command given after that function. If a $VERBOSE variables is set
# to 0 a result of this command will not be shown. When $VERBOSE is set to 1 all
# output will be printed.
#
# $@ - Command to execute.
exec_cmd ()
{
  case $VERBOSE in
    0)
      $@ &> /dev/null ;;
    1)
      echo "Exec: $@"; "$@" ;;
  esac
}

# Checks if a command exists.
#
# $1 - A command to check.
command_exists ()
{
  type "$1" &> /dev/null;
}

# Asks a user for the root password and store it in the ROOT_PASSWORD variable.
sudo_prompt ()
{
  sudo -k
  local IS_ROOT=$(echo "$ROOT_PASSWORD" | sudo -S -p "" -s -- whoami 2> /dev/null)

  if [[ $IS_ROOT != "root" ]]; then
    echo_warn "The root is required to run some commands in this script:"
  fi

  until [[ $IS_ROOT == "root" ]]; do
    printf "Root password: "
    read -s ROOT_PASSWORD
    echo "***"

    sudo -k
    IS_ROOT=$(echo "$ROOT_PASSWORD" | sudo -S -p "" -s -- whoami 2> /dev/null)
  done

  echo
}

# Runs commands as the root using a password from the ROOT_PASSWORD variable.
#
# $@ - Commands to execute.
sudo_wrapper ()
{
  if [[ $VERBOSE == 1 ]]; then
    echo "ROOT exec: $@"
  fi

  sudo -k
  echo "$ROOT_PASSWORD" | sudo -S -p "" -- /bin/bash -c "$@"
}

# Checks if current OS is a Linux.
is_linux ()
{
  if [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    return $true;
  else
    return $false;
  fi;
}

# Checks if current OS is a Mac OS.
is_mac ()
{
  if [[ "$(uname)" == "Darwin" ]]; then
    return $true;
  else
    return $false;
  fi;
}
