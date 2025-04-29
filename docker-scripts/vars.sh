#!/usr/bin/env bash

if [ "${IN_DOCKER:-}" ];then
    DATA_DIR=${API_DATA_DIR:-/data/db}
    LOG_DIR=${API_LOG_DIR:-/data/logs}
    CONFIG_DIR=${API_CONFIG_DIR:-/data/config}
else
    DATA_DIR=${API_DATA_DIR:-$CONDA_PREFIX/var/freva-rest-server/$SERVICE}
    LOG_DIR=${API_LOG_DIR:-$CONDA_PREFIX/var/log/freva-rest-server/$SERVICE}
    CONFIG_DIR=$CONDA_PREFIX/share/freva-rest-server
fi
mkdir -p $DATA_DIR $LOG_DIR $CONFIG_DIR
if [ "$CONDA_PREFIX" ];then
    export PATH=$PATH:$CONDA_PREFIX/bin
fi
USER=$(whoami)
