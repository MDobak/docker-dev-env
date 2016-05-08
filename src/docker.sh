#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DOCKER_SH=1

UTILS_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! type _UTILS_SH &> /dev/null; then
  . $UTILS_BASE_DIR/util.sh
fi

# Removes images and containers created by this script and rebuilds images.
#
# $1 - An image name.
# $2 - A Dockerfile directory.
docker_dev_container_rebuild ()
{
  local NAME=$1;
  local DIR=$2;

  if docker ps | grep -q "\s$NAME$"; then
    echo_step "Removing a $NAME container"
    # We intentionaly finds containers based on thier name rather than an image
    # name beacuse we want remove only containers created by this script.
    exec_step docker rm -f $(docker ps | grep "^[^\s]+\s+$NAME\s+" | awk '{print $1}')
  fi

  if docker images | grep -q "^$NAME\s"; then
    echo_step "Removing a $NAME image"
    exec_step docker rmi -f $NAME
  fi

  echo_step "Bulding a $NAME image"
  exec_step docker build -t $NAME $DIR
}

# Builds an image if not exists and then create a new container or starts
# existing one. Containers will have the same name as an image.
#
# $1 - An image name.
# $2 - A Dockerfile directory.
setup_dev_container ()
{
  local NAME=$1
  local DIR=$2
  local BUILD=$true
  local ARGS=""

  shift 2

  for ARG in $@; do
    if [[ $ARG == '--build-only' ]]; then
      BUILD=$false
    else
      ARGS="$ARGS $ARG"
    fi
  done

  if ! docker images | grep -q "^$NAME\s"; then
    docker_dev_container_rebuild $NAME $DIR
  fi

  if [[ $BUILD == $true ]]; then
    local CURRENT_ID=$(docker ps -a | grep "\s$NAME$" | awk '{print $1}')
    if [[ -z $CURRENT_ID ]]; then
      echo_step "Running a fresh \"$NAME\" container"
      exec_step docker run $ARGS --name="$NAME" $NAME
    else
      echo_step "Starting a \"$NAME\" container"
      exec_step docker start $CURRENT_ID
    fi
  else
    echo_step_info "An image \"$NAME\" is not runnable"
  fi
}

# Removes umtagged Docker images.
docker_remove_untagged_images ()
{
  IMAGES_TO_REMOVE=$(docker images --filter "dangling=true" -q --no-trunc)

  if [[ ! -z $IMAGES_TO_REMOVE ]]; then
      echo_step "Removing untaged images"
      exec_cmd docker rmi $IMAGES_TO_REMOVE
      echo_step_result_ok
  fi
}
