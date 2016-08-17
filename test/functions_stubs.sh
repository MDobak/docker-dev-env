#!/bin/bash

run_as_user ()
{
  "$@"
  return $?
}

err_catch ()
{
  "$@"
  return $?
}
