#!/bin/bash
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>

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
