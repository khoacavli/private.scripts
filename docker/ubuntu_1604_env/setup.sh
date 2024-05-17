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

DOCKER_CONTAINER=dev_env

__USERNAME=$(whoami)
__UID=$(id -u $1)
__GID=$(id -g $1)
__DOCKER_IMG=sdx35_image

sed -e "s/{USERNAME}/$__USERNAME/g" \
    -e "s/{UID}/$__UID/g" \
    -e "s/{GID}/$__GID/g" \
    Dockerfile.template > Dockerfile

docker_container_force_remove $DOCKER_CONTAINER
docker rmi $__DOCKER_IMG
docker build -t $__DOCKER_IMG .

DIR_WHITELIST=(
  "/home/$__USERNAME/.ssh"
)

for path in "${DIR_WHITELIST[@]}"; do
  if [ -d "$path" ]; then
    CMD+=" -v $path:$path"
  else
    echo "Warning: Source path $path does not exist."
  fi
done

docker run --name $DOCKER_CONTAINER \
    -dit --privileged --network host \
    -e "TERM=xterm-256color" \
    -u $__USERNAME -h $__USERNAME \
    -v /dev/:/dev/ \
    -v /etc/localtime:/etc/localtime:ro \
    -v /mnt:/mnt \
    $CMD \
    $__DOCKER_IMG bash
