#!/bin/bash
#
# The MIT License (MIT)
# Copyright © 2016 Michał Dobaczewski <mdobak@gmail.com>
#

_DOCKER_SH=1

# Checks if a container is created by this scrpt.
#
# $1 - A container name.
docker_is_dev_env_container ()
{
  docker exec $1 test -f /etc/docker-dev-env

  return $?
}

# Removes images and containers created by this script and rebuilds images.
#
# $1 - An image name.
# $2 - A Dockerfile directory.
docker_dev_container_rebuild ()
{
  local NAME=$1;
  local DIR=$2;

  if docker ps | grep -q "\s$NAME$"; then
    # We intentionaly finds containers based on thier name rather than an image
    # name beacuse we want remove only containers created by this script.
    docker rm -f $(docker ps | grep "^[^\s]+\s+$NAME\s+" | awk '{print $1}') > /dev/null
  fi

  if docker images | grep -q "^$NAME\s"; then
    docker rmi -f $NAME > /dev/null
  fi

  err_catch verbose docker build -t $NAME $DIR

  return $?
}

# Builds an image if not exists and then create a new container or starts
# existing one. Containers will have the same name as an image.
#
# $1 - An image name.
# $2 - Hostname.
# $3 - A Dockerfile directory.
# $4 - Image name to build if container does not exists.
docker_setup_dev_container ()
{
  local NAME=$1
  local HOSTNAME=$2
  local DIR=$3
  local IMAGE=$4
  local BUILD=$true

  local ARGS=""
  local STATUS=0

  shift 4

  for ARG in $@; do
    if [[ $ARG == '--build-only' ]]; then
      BUILD=$false
    else
      ARGS="$ARGS $ARG"
    fi
  done

  if ! (docker images | grep -q "^$NAME\s") && [[ -f $DIR/Dockerfile ]]; then
    docker_dev_container_rebuild $NAME $DIR
    STATUS=$?
  fi

  if [[ $BUILD == $true ]]; then
    local CURRENT_ID=$(docker ps -a | grep "\s$NAME$" | awk '{print $1}')
    if [[ -z $CURRENT_ID ]]; then
      verbose docker run $ARGS \
        --hostname="$HOSTNAME" \
        --name="$NAME" \
        -e "DEV_NAME=$NAME" \
        -e "DEV_HOSTNAME=$HOSTNAME" \
        $IMAGE

      STATUS=0
    else
      docker start $CURRENT_ID > /dev/null
      STATUS=0
    fi

    # Create empty file to mark this container as created by this script.
    docker exec $NAME touch /etc/docker-dev-env
  fi

  return $STATUS
}

# Removes umtagged Docker images.
docker_remove_untagged_images ()
{
  IMAGES_TO_REMOVE=$(docker images --filter "dangling=true" -q --no-trunc)

  if [[ ! -z $IMAGES_TO_REMOVE ]]; then
    docker rmi $IMAGES_TO_REMOVE
  fi
}
