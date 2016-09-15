#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_TRAP_SH=1

# Prints simple stack tracxe.
err_trace ()
{
  local FRAME=1

  echo -e "${CRED}  Stack trace:"

  CALLER=$(caller $FRAME)
  until [[ -z $CALLER ]]; do
    ((FRAME++))
    echo -e "  ${CLBLUE}\xE2\x80\xA2${CRED} ${CALLER[0]}";
    CALLER=$(caller $FRAME)
  done

  echo -e $CRESET;
}

# Display error message catched by trap builtin.
err_trap ()
{
  local LINENO="$1"
  local MESSAGE="$2"
  local CODE="${3:-1}"

  if [[ -n "$message" ]] ; then
    echo_fatal "${MESSAGE}. Exiting with status ${CODE}" $false
  else
    echo_fatal "Exiting with status ${CODE}" $false
  fi

  err_trace

  exit -1
}

# Executes a command and show an error if command fail.
#
# $@ - The command to execute.
err_catch ()
{
  local STATUS=0

  "$@" || STATUS=$? || true

  if [[ $STATUS != 0 ]]; then
    if [[ $true == $_STEP ]]; then
      echo_step_result_fail
    fi

    echo_fatal "Command \"$@\" failed with status $STATUS" $false
    err_trace
    exit -1
  fi
}

trap 'err_trap ${LINENO}' ERR
