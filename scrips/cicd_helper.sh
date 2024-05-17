#!/bin/bash

print_usage()
{
    echo "cicd_helper.sh [options]"
    echo "  options:"
    echo "  -h: print help"
    echo "  -d: dry run: print what will be done"
    echo "  -s: use 'sudo' when it is needed"
    echo "  -w: working path to mount at /data/"
    echo "  -t: tool path to mount at /pkg/"
    echo "  -n: number ( 1->99 )"
    echo "  -r: force gen docker img"
    echo "NOTE"
    echo "  This container base on ghcr.io/cavli-wireless/sdx35/owrt:latest"
    echo "  Create user which refer from caller env ( result of whoami )"
    echo "  Mount and setup env to build"
    echo "  USER MUST PREPARE TOOLS BUILD"
}

docker_container_force_remove() 
{
    CONTAINER_NAME=$1
    if [ "$(docker ps -a -q -f name=${CONTAINER_NAME})" ]; then
        if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
            docker stop ${CONTAINER_NAME}
        fi
        docker rm ${CONTAINER_NAME}
    fi
}

check_local_docker_image_exists() 
{
    local image_name=$1
    local tag=$2

    # Get the list of images and filter by name and tag
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image_name}:${tag}$"; then
        echo "Image '${image_name}:${tag}' exists locally."
        return 0
    else
        echo "Image '${image_name}:${tag}' does not exist locally."
        return 1
    fi
}

# Parse command line arguments
while getopts "hdsrw:t:n:k:" flag; do
  case $flag in
    d) DRYRUNCMD="echo";;
    s) SUDO="sudo";;
    r) RESET=true;;
    w) CICD_ROOT=$OPTARG;;
    t) TOOL_PATH=$OPTARG;;
    n) NUMBER=$OPTARG;;
    k) KEY=$OPTARG;;
    *) print_usage; exit 1;;
  esac
done

shift $(( $OPTIND - 1 ))

if [ -z $KEY ] || [ -z $CICD_ROOT ] || [ -z $TOOL_PATH ]; then
    echo "Please give me, WORKPATH and TOOLPATH"
    exit 1
fi

DOCKER_USER=cavli
DOCKER_CONTAINER=cicd_sdx35_$NUMBER
DOCKER_IMG=ghcr.io/cavli-wireless/sdx35/owrt:cicd
image="ghcr.io/cavli-wireless/sdx35/owrt"
tag="cicd"

docker_container_force_remove $DOCKER_CONTAINER

if [[ $RESET == "true" ]]; then
    echo "Remove $DOCKER_IMG"
    docker rmi $DOCKER_IMG
fi

check_local_docker_image_exists $image $tag 
RETVAL=$?
if [[ $RETVAL -eq 1 ]]; then
    cp -vf Dockerfile.cicd Dockerfile
    if docker build -t $DOCKER_IMG .; then
        echo "Create img SUCCESS"
    else
        echo "Create img FAILED, stop"
        exit 1
    fi
fi

if [ ! -f actions-runner-linux-x64-2.316.1.tar.gz ]; then
    curl -o actions-runner-linux-x64-2.316.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
else
    echo "actions-runner-linux-x64-2.316.1.tar.gz exist"
fi

mkdir -p $CICD_ROOT/$DOCKER_CONTAINER

docker run --name $DOCKER_CONTAINER \
    -dit \
    --privileged \
    --network host \
    -u $DOCKER_USER \
    -h localhost \
    -v /dev/bus/usb/:/dev/bus/usb \
    -v /etc/localtime:/etc/localtime:ro \
    -v $CICD_ROOT/$DOCKER_CONTAINER:$CICD_ROOT/$DOCKER_CONTAINER \
    -v /var/run/docker.sock:/var/run/docker.sock \
    $DOCKER_IMG bash

docker exec -u root $DOCKER_CONTAINER chown cavli:cavli $CICD_ROOT/$DOCKER_CONTAINER
docker exec -u root $DOCKER_CONTAINER rm -rf $CICD_ROOT/$DOCKER_CONTAINER/*
docker cp actions-runner-linux-x64-2.316.1.tar.gz $DOCKER_CONTAINER:$CICD_ROOT/$DOCKER_CONTAINER
docker exec -u cavli -w $CICD_ROOT/$DOCKER_CONTAINER $DOCKER_CONTAINER tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz
docker exec -u cavli -w $CICD_ROOT/$DOCKER_CONTAINER $DOCKER_CONTAINER rm -fv ./actions-runner-linux-x64-2.316.1.tar.gz
docker exec -u cavli -w $CICD_ROOT/$DOCKER_CONTAINER $DOCKER_CONTAINER bash config.sh \
    --url https://github.com/cavli-wireless/SDX35 \
    --name $DOCKER_CONTAINER \
    --token $KEY

DOCKER_GID=$(docker exec -it $DOCKER_CONTAINER  stat -c "%g" "/var/run/docker.sock")
DOCKER_GID=$(echo -n "$DOCKER_GID" | tr -d '\r\n')
docker exec -u root ${DOCKER_CONTAINER} groupmod -g ${DOCKER_GID} docker
docker exec -u root ${DOCKER_CONTAINER} usermod -aG docker cavli
docker stop $DOCKER_CONTAINER
docker commit $DOCKER_CONTAINER $DOCKER_IMG
docker remove $DOCKER_CONTAINER
docker run --name $DOCKER_CONTAINER \
    -dit --privileged --network host \
    -u $DOCKER_USER \
    -h localhost \
    -v /dev/bus/usb/:/dev/bus/usb \
    -v /etc/localtime:/etc/localtime:ro \
    -v $TOOL_PATH:/pkg/ \
    -v $CICD_ROOT/$DOCKER_CONTAINER:$CICD_ROOT/$DOCKER_CONTAINER \
    -v /var/run/docker.sock:/var/run/docker.sock \
    $DOCKER_IMG bash $CICD_ROOT/$DOCKER_CONTAINER/run.sh
