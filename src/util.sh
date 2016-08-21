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
    exit -1;
  fi;

  return $true;
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

# Checks if script is being run by root.
check_root ()
{
  if [[ $EUID -ne 0 ]]; then
    echo_fatal "This script must be run as root!" 1>&2
    exit 1
  fi
}

# Check if script is being run using sudo command.
check_sudo ()
{
  if [[ -z $SUDO_USER ]] && [[ $SUDO_USER != "roor" ]]; then
    echo_fatal "This script must be run using sudo as non root user!" 1>&2
    exit 1
  fi
}

# Prints an error messages.
#
# $1 - An error message.
echo_error ()
{
  printf "$CRED$1$CRESET\n"
}

# Prints a warning messages.
#
# $1 - A warning message.
echo_warn ()
{
  printf "$CORANGE$1$CRESET\n"
}

# Prints a success messages.
#
# $1 - A success message.
echo_success ()
{
  printf "$CYELLOW$1$CRESET\n"
}

# Prints a step name withthe  "INFO" status.
#
# $1 - A message.
echo_log ()
{
  if [[ $VERBOSE != 0 ]]; then
    printf "$CBLUE$1\n"
  fi
}

# Prints a fatal error message and interrupts the script execution.
#
# $1 - A success message.
# $2 - Exit immediately ($true or $false, by default $true)
echo_fatal ()
{
  local EXIT_IMMEDIATLY=$2

  echo
  echo_error  "--------------------------------------------------------------------------------"
  echo_error "  Script failed!                                                              "
  echo_error "  $1"
  echo_error  "--------------------------------------------------------------------------------"
  echo

  if [[ -z "$EXIT_IMMEDIATLY" ]] || [[ "$EXIT_IMMEDIATLY" == "$true" ]]; then
    exit -1;
  fi
}

# Prints current step message. After this function you must use one
# of these functions: echo_step_result_ok, echo_step_result_fail or
# echo_step_result_auto to print the result.
#
# $1 - Step message.
echo_step ()
{
  _STEP=$true

  if [[ $VERBOSE == 0 ]]; then
    printf "$CRESET[    ] $CYELLOW$1$CRESET\r"
  else
    printf "$CYELLOW$1$CRESET\n"
  fi
}

# Should be used to execute step commands after a echo_step.
# This function executes a step (using the exec_cmd function) and immediately
# after it shows the step status using the echo_step_result_auto.
#
# $@ - A command to execute.
exec_step ()
{
  local STATUS=0

  "$@"
  STATUS=$?

  if [[ $true == $_STEP ]]; then
    echo_step_result_auto
  fi

  _STEP=$false

  return $?
}

# Prints the "OK" result for echo_step function.
echo_step_result_ok ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "$CYELLOW[ OK ]\n"
  fi
}

# Prints the "FAIL" result for echo_step function.
echo_step_result_fail ()
{
  if [[ $VERBOSE == 0 ]]; then
    printf "$CRED[FAIL]\n"
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

# Prints a step name with the "SKIP" status.
#
# $1 - A message.
echo_step_skip ()
{
  printf "$CLBLUE[SKIP] $CYELLOW$1$CRESET\n"
}

# Execute the command given after that function. If a $VERBOSE variables is set
# to 0 a result of this command will not be shown. When $VERBOSE is set to 1 all
# output will be printed.
#
# $@ - Command to execute.
verbose ()
{
  local STATUS=0

  if [[ $VERBOSE == 1 ]]; then
    echo -e "$CBLUE\xE2\x94\x8F $CRESET$(caller)$CRESET"
    echo -e "$CBLUE\xE2\x94\x97 $CRESET$@$CRESET"

    "$@"
    STATUS=$?

    printf "\n"
  else
    "$@" &> /dev/null
    STATUS=$?
  fi

  return $STATUS
}

run_as_user ()
{
  sudo -u $SUDO_USER "$@"

  return $?
}

# Copy permission of one file to another.
#
# $1 - Source.
# $2 - Target.
copy_permissions ()
{
  chmod $( stat -f '%p' "$1" ) "${@:2}"
}

# Checks if a command exists.
#
# $1 - A command to check.
command_exists ()
{
  type "$1" &> /dev/null;
}

# Checks if current OS is a Linux.
is_linux ()
{
  if [[ "$(uname -s)" == "Linux" ]]; then
    return $true;
  else
    return $false;
  fi;
}

# Checks if current OS is a Mac OS.
is_mac ()
{
  if [[ "$(uname -s)" == "Darwin" ]]; then
    return $true;
  else
    return $false;
  fi;
}
