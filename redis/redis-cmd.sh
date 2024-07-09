#!/bin/sh
#
# Set the ACL of the redis instance
# Strip any rights from the redis default user.
echo "user default off -@all" > /tmp/redis.conf
REDIS_PASSWORD="${REDIS_PASSWORD:+>$REDIS_PASSWORD}"

## Add only a selection of user rights, if no user was passed via env use the default user same for password
echo "user ${REDIS_USERNAME:-default} on +@all ~* &* ${REDIS_PASSWORD:-nopass}" >> /tmp/redis.conf

# Enable sys logging, default notice level
echo "loglevel ${REDIS_LOGLEVEL:-notice}" >> /tmp/redis.conf
echo "syslog-enabled yes" >> /tmp/redis.conf

# Check if we have TLS encryption and enable it we have one.
if [ -f "$REDIS_SSL_CERTFILE" ] && [ -f "$REDIS_SSL_KEYFILE" ];then
    echo "port 0" >> /tmp/redis.conf
    echo "tls-port 6379" >> /tmp/redis.conf
    echo "tls-cert-file $REDIS_SSL_CERTFILE" >> /tmp/redis.conf
    echo "tls-key-file $REDIS_SSL_KEYFILE" >> /tmp/redis.conf
    echo "tls-ca-cert-file $REDIS_SSL_CERTFILE" >> /tmp/redis.conf
fi
cat /tmp/redis.conf
redis-server /tmp/redis.conf
