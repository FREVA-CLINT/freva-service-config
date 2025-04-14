#!/usr/bin/env bash
order=(podman docker)
path=""
if [ -z "$1" ];then
    echo "Usage: $0 <image_name> >&2"
    exit 1
fi
for cmd in ${order[*]};do
    if [ "$(which $cmd 2> /dev/null)" ];then
        path=$(which $cmd)
        break
    fi
done
if [ -z "$path" ];then
    echo "Docker nor Podman on the system. >&2"
    exit 1
fi


if [ "$1" = "redis" ];then
    version=$($path run -it redis sh -c 'echo $REDIS_VERSION')
else
    version=$($path inspect --format='{{ index .Config.Labels "org.opencontainers.image.version" }}' $1)
fi

if [ -z "$version" ];then
    echo "Error: could not find version for $1 >&2"
    exit 1
fi
echo $version
