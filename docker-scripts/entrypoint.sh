#!/bin/sh
set -e

APP_UID=${APP_UID:-0}
APP_GID=${APP_GID:-0}

export DATA_DIR=/data/db
export LOG_DIR=/data/logs
export CONFIG_DIR=/data/config
export BACKUP_DIR=/backup
export PATH=/opt/conda/bin:$PATH
export USER=$(whoami)

mkdir -p $DATA_DIR $LOG_DIR $CONFIG_DIR $BACKUP_DIR || true
if [ "$(id -u)" = "0" ]; then
    exec gosu "${APP_UID}:${APP_GID}" "$@"
else
    exec "$@"
fi
