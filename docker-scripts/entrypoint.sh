#!/bin/sh
set -e
if [ "$DEBUG" = "true" ]; then
    set -x
fi

export DEBUG
export DATA_DIR=/data/db
export LOG_DIR=/data/logs
export CONFIG_DIR=/data/config
export BACKUP_DIR=/backup
export PATH=/opt/conda/bin:$PATH
export USER=$(whoami) 2> /dev/null || $(id -u)
mkdir -p $DATA_DIR $LOG_DIR $CONFIG_DIR $BACKUP_DIR
exec "$@"
