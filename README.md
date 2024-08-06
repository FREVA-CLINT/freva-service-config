# Freva services

This repository holds all definitions for Docker images to create services
that are needed to run Freva in production and development mode. Currently
those services are:

- MariaDB
- Apache Solr
- Redis
- Keycloak Open ID Connect service via OpenLDAP federation

Any changes to the configurations like MariaDB table definitions, Apache
Solr `managed_schema.xml` file or Redis startup script should be done here.

## Utility script for preparing services.
The ``dev-utils.py`` script provides useful commands to prepare the start of
docker containers or interact with a development service. The following commands
are available:

```console
python dev-utils.py --help
positional arguments:
  {gen-certs,oidc,kill}
    gen-certs           Generate a random pair of public and private certificates.
    oidc                Wait for the oidc service to start up.
    kill                Kill a running process.

options:
  -h, --help            show this help message and exit
```

To get help of each sub-command you can use the ``--help`` flag for the
sub-command in question. For example:

```console
python dev-utils.py gen-certs --help
usage: dev-utils.py gen-certs [-h] [--cert-dir CERT_DIR]

options:
  -h, --help           show this help message and exit
  --cert-dir CERT_DIR  The ouptut directory where the certs should be stored. (default: /home/wilfred/workspace/freva-service-config/certs)
```

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
python dev-utils.py gen-certs &&
docker run -v ./redis/redis-cmd.sh:/usr/local/bin/redis-cmd:z \
       -v ./certs:/certs redis:latest /usr/local/bin/redis-cmd
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
            protection. The same applies to TLS certificates. If you choose
            none, none will be used. Once you've chosen usernames, passwords
            and/or certificates make sure this information is passed
            on to the client(s) making connections to the server.

### Keycloak
[Keycloak](https://www.keycloak.org) is pre configured as an identity provider.
The keycloak configuration defines a *freva* realm. The realm defines a 
``client_id=freva``. This freva realm has also
and openLDAP server configured. The openLDAP server configuration defines a
couple of dummy users:

- uid: johndoe, password: johndoe123, mail: john@example.com
- uid: janedoe, password: janedoe123, mail: jane@example.com
- uid: alicebrown, password: alicebrown123, mail: alice@example.com
- uid: bobsmith, password: bobsmith123, mail: bob@example.com
- uid: lisajones, password: lisajones123, mail: lisa@example.com
- uid: bobsmith, password: bobsmith123, mail: bob@existing.com

More information on the LDAP settings can be retrieved from the 
``keycloak/users.ldif`` config file.

To setup the openLDAP server use the following
docker command:

```console
docker run -e LDAP_ADMIN_PASSWORD=admin_password -e LDAP_ADMIN_USERNAME=admin \
 -p 389:389 -p 636:636 -v ./keycloak/users.ldif:/container/service/slapd/assets/config/bootstrap/ld
 osixia/openldap:latest --copy-service
```

To setup the keycloak service use the following command:

```console
python dev-utils.py gen-certs &&
docker run -e KEYCLOAK_ADMIN=keycloak -e KEYCLOAK_ADMIN_PASSWORD=secret \
 -e KC_HEALTH_ENABLED=true -e KC_METRICS_ENABLED=true \
 -e JAVA_OPTS_APPEND="-Djava.net.preferIPv4Stack=true" \
 -v ./certs:/certs -v ./keycloak/import:/opt/keycloak/data/import:z \
 -p 8080:8080 -p 8443:8443 quay.io/keycloak/keycloak \
 start-dev --hostname-strict=fals --import-realm Dkeycloak.migration.strategy=OVERWRITE_EXISTING

```

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
