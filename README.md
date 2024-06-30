# Freva services

This repository holds all definitions for Docker images to create services
that are needed to run Freva in production and development mode. Currently
those services are:

- MariaDB
- Apache Solr
- Redis

Any changes to the configurations like MariaDB table definitions, Apache
Solr managed_schema.xml file or Redis startup script should be done here.

## Using the config files when creating images

Usage of the configurations within the Solr, MariaDB and Redis containers should
be realised by adding the files via *volumes* to the container during creation.


### MariaDB

```console
docker run -v path/to/freva-service-config/mysql/create-users.sql:/docker-entrypoint-initdb.d/001_create_users.sql:ro
```

The following environment variables should be
considered when starting the **MariaDB** container:

- `MARIADB_ROOT_PASSWORD`: MariaDB root password for the container.
- `MARIADB_USER`: 'normal' MariaDB user, Freva will be connecting to the DB with
  this user name.
- `MARIADB_PASSWORD`: password for the 'normal' MariaDB user name.
- `MARIADB_DATABASE`: the name of the database where all Freva related tables
  are stored.

### Apache Solr

For Apache Solr two files are need:

```console
docker run -v path/to/freva-service-config/solr/managed_schema.xml:/opt/solr/managed_schema.xml:ro \
       path/to/freva-service-config/sorl/create_cores.sh:/docker-entrypoint-initdb.d/create_cores.sh:ro
```

For the **Apache Solr** container consider the following environment variables:

- `CORE`: name of the standard core holding information about files (default:
   file)
- `SOLR_HEAP`: memory allocated for the solr process.
- `NUM_BACKUPS`: number of backups to keep. See backup for more details.


### Redis
A secure Redis instance using ACL's and TLS connections can be set up using
the following docker command:

```console
docker run -v path/to/freva-service-config/redis/redis-cmd.sh:/usr/local/bin/redis-cmd:z \
       path/to/tls-certs:/certs redis:latest /usr/local/bin/redis-cmd
```

The following environment variables are considered by the startup script:

- `REDIS_USERNAME`: user name of the redis db user
- `REDIS_PASSWORD`: password for the redis db user
- `REDIS_LOGLEVEL`: redis log level
- `REDIS_SSL_CERTFILE`: path to the ssl cert file (should be in /cert)
- `REDIS_SSL_KEYFILE`: path to the ssl key file

> **Note:** The above environment variables are optional, if for example you do
            not set the `REDIS_USERNAME` and `REDIS_PASSWORD` the server will
            be started using the default redis db user without password
            protection. The same applies for TLS certificates. If you choose
            none, none will be used. Once you've chosen usernames, passwords
            and certificates make sure this information client(s) is passed
            on to all clients making connections to the server.

### Backup of data
If you need a simple backup functionality, you can add the `daily_backup.sh`
script in the same manner.

Setting up the volumes as outlined above will instruct the containers to
automatically creating new MariaDB tables (if not existing) and Solr cores
(if not existing).


If you added the `daily_backup.sh` files via a volume to the container you can
setup simple crontab to create backups on the *host* machine running
the container. A simple crontab example could like like this.

```
# m    h    dom   mon    dow      command
0      5    *     *      *        docker exec container-name bash -c /usr/local/bin/daily_backup
```
