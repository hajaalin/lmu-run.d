#!/bin/bash

# Script to start and connect to a container with SSH or by attaching.
# Modified from https://pelle.io/delivering-gui-applications-with-docker/

usage() {
  echo "$0 [options] <dev|fiji|cp>"
  echo "Options:"
  echo "-n container_name"
  echo "-i /input_folder"
  echo "-o /output_folder"
  echo "-c config_container"
  echo "-v volume_container"
  echo "-t (run a test version of container)"
  exit 1
}

while getopts ":n:i:o:c:v:t" opt; do
  case $opt in
    i)
      echo "-i was triggered, Parameter: $OPTARG" >&2
      OPT_INPUT=$OPTARG
      ;;
    o)
      echo "-o was triggered, Parameter: $OPTARG" >&2
      OPT_OUTPUT=$OPTARG
      ;;
    c)
      echo "-c was triggered, Parameter: $OPTARG" >&2
      OPT_CONFIG=$OPTARG
      ;;
    v)
      echo "-v was triggered, Parameter: $OPTARG" >&2
      OPT_VOLUME_CONTAINER=$OPTARG
      ;;
    n)
      echo "-n was triggered, Parameter: $OPTARG" >&2
      OPT_NAME=$OPTARG
      ;;
    t)
      echo "-t was triggered, Parameter: $OPTARG" >&2
      OPT_TEST="_test"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# tag for image name
IMAGE=$1
if [ -z $IMAGE ]; then
  usage
fi

# select image to run
SSH="no"
if [ $IMAGE == "dev" ]; then
    DOCKER_IMAGE_NAME="hajaalin${OPT_TEST}/devbox"
elif [ $IMAGE == "fiji" ]; then
    DOCKER_IMAGE_NAME="hajaalin${OPT_TEST}/fijibox-lifeline"
    SSH="yes"
elif [ $IMAGE == "cp" ]; then
    DOCKER_IMAGE_NAME="hajaalin${OPT_TEST}/cellprofilerbox"
    SSH="yes"
else
    usage
fi
echo $DOCKER_IMAGE_NAME

# local name for the container
DOCKER_CONTAINER_NAME=${OPT_NAME:-$IMAGE-`date +%Y%m%d%H%M`}
echo $DOCKER_CONTAINER_NAME

# local folders to mount
INPUT=${OPT_INPUT:-"/mnt/lmu-active"}
OUTPUT=${OPT_OUTPUT:-"$HOME/tmp/container_output/$DOCKER_IMAGE_NAME/$DOCKER_CONTAINER_NAME"}
mkdir -p $OUTPUT
chmod a+rwx $OUTPUT
echo $INPUT
echo $OUTPUT

# container with config data (GitHub etc.)
CONFIG_CONTAINER_NAME=${OPT_CONFIG:-"hajaalin-data"}
echo $CONFIG_CONTAINER_NAME


# check if container already present
TMP=$(docker ps -a | grep ${DOCKER_CONTAINER_NAME})
CONTAINER_FOUND=$?

TMP=$(docker ps | grep ${DOCKER_CONTAINER_NAME})
CONTAINER_RUNNING=$?

CMD=""
if [ $CONTAINER_FOUND -eq 0 ]; then
    echo -n "container '${DOCKER_CONTAINER_NAME}' found, "
    if [ $CONTAINER_RUNNING -eq 0 ]; then
	echo "already running"
    else
	echo -n "not running, starting..."
	TMP=$(docker start ${DOCKER_CONTAINER_NAME})
	echo "done"
    fi

else
    echo "container '${DOCKER_CONTAINER_NAME}' not found, creating..."
    CMD="docker run --name ${DOCKER_CONTAINER_NAME}"

    # mount volumes
    CMD="$CMD --volumes-from $CONFIG_CONTAINER_NAME"
    if [ -n "$OPT_VOLUME_CONTAINER" ]; then
	CMD="$CMD --volumes-from $OPT_VOLUME_CONTAINER"
    else
        CMD="$CMD -v $INPUT:/input"
        CMD="$CMD -v $OUTPUT:/output"
    fi

    # mount docker inside devbox, run interactive
    if [ $IMAGE == "dev" ]; then
	CMD="$CMD -v /var/run/docker.sock:/var/run/docker.sock"
	CMD="$CMD -v $(which docker):$(which docker)"
	CMD="$CMD -ti"
    # run ssh boxes as server, expose ports
    else
	CMD="$CMD -d -P"
    fi

    CMD="$CMD ${DOCKER_IMAGE_NAME}"

    echo $CMD
    $CMD
    echo "done"
fi

# connect with SSH
if [ $SSH == "yes" ]; then
    echo "connect with SSH"
    #wait for container to come up
    sleep 2

    # find ssh port
    SSH_URL=$(docker port ${DOCKER_CONTAINER_NAME} 22)
    SSH_URL_REGEX="(.*):(.*)"

    SSH_INTERFACE=$(echo $SSH_URL | awk -F  ":" '/1/ {print $1}')
    SSH_PORT=$(echo $SSH_URL | awk -F  ":" '/1/ {print $2}')

    echo "ssh running at ${SSH_INTERFACE}:${SSH_PORT}"

    ssh -vvvv -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -X dev@${SSH_INTERFACE} -p ${SSH_PORT}

# attach to previously created container
else
    "connect with docker attach"
    docker attach $DOCKER_CONTAINER_NAME
fi
