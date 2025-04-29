#!/bin/sh
set -e

export DATA_DIR=/data/db
export LOG_DIR=/data/logs
export CONFIG_DIR=/data/config
export BACKUP_DIR=/backup
export PATH=/opt/conda/bin:$PATH
export USER=$(whoami)

exec "$@"
