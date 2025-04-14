#!/usr/bin/env bash
#set -e pipefail
order=(podman docker)
path=""
if [ -z "$1" ] || [ ! -f "$1/Dockerfile" ];then
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

image=$(head -n1 $1/Dockerfile | awk '{print $NF}')
image_version=$(echo $image | cut -d : -f2)

$path pull $image

if [ "$image_version" != "latest" ];then
    version=$image_version
elif [ "$1" = "redis" ];then
    version=$($path run -it redis sh -c 'echo $REDIS_VERSION')
else
    version=$($path inspect --format='{{ index .Config.Labels "org.opencontainers.image.version" }}' $1)
fi

if [ -z "$version" ];then
    echo "Error: could not find version for $1 >&2"
    exit 1
fi
echo version=$version > /tmp/image-version-$1.txt
echo "Found version for $1: $version"
