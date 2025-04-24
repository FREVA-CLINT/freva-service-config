#!/usr/bin/env bash

# Perform a healthcheck for the specified service.
set -o nounset -o pipefail -o errexit

if [ "${TEST:-}" ]; then
    /usr/local/bin/start-service &
    PID=$!
    sleep 10
    trap "kill -9 $PID &> /dev/null || true" EXIT
fi

case "$SERVICE" in
    solr)
        solr status >/dev/null 2>&1
        ;;
    mysql)
        if [ -f "/tmp/mysqld.pid" ];then
            read mysqld_pid < "/tmp/mysqld.pid"
            if kill -0 $mysqld_pid 2>/dev/null ; then
                exit 0
            fi
        fi
        echo "MySQL server not running"
        exit 1
        ;;
    mongo)
        python -c "import pymongo; \
            pymongo.MongoClient('mongodb://$API_MONGO_USER:$API_MONGO_PASSWORD@localhost:27017?timeoutMS=2000').list_database_names()" \
            >/dev/null 2>&1
        ;;
    redis)
        if [ -f "/tmp/redis-server.pid" ];then
            read redis_pid < "/tmp/redis-server.pid"
            if kill -0 $redis_pid 2>/dev/null ; then
                exit 0
            fi
        fi
        echo "Redis-server not running"
        exit 1

        if ! pgrep -x redis-server > /dev/null; then
            exit 1
        fi
        redis-cli ping | grep -q PONG
        ;;
    *)
        echo "❌ Unknown service: $SERVICE" >&2
        exit 1
        ;;
esac
