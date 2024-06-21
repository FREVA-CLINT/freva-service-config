# Freva services

This repository holds all definitions for Docker images to create all services
that are needed to run Freva in production and development mode.

Any changes to the configurations like MariaDB table definitions or the Apache
Solr managed_schema.xml file should be done here.

An automated pipeline builds the images and pushes them to the DKRZ registry
where they can be pulled for usage in production or development mode.

## Using the config files when creating images

Usage of the configurations within the Solr and MariaDB containers should
be realised by adding the files via *volumes* to the container during creation.

For MariaDB this could be:

```
docker run -v path/to/freva-service-config/mysql/create-users.sql:/docker-entrypoint-initdb.d/001_create_users.sql:ro
```

For Apache Solr two files are need:

```
docker run -v path/to/freva-service-config/solr/managed_schema.xml:/opt/solr/managed_schema.xml:ro \
       path/to/freva-service-config/sorl/create_cores.sh:/docker-entrypoint-initdb.d/create_cores.sh:ro
```

If you need a simple backup functionality, you can add the `daily_backup.sh`
script in the same manner.

Setting up the volumes as outlined above will instruct the containers to
automatically creating new MariaDB tables (if not existing) and Solr cores
(if not existing).

The following environment variables should be
considered when starting the **MariaDB** container:

- `MARIADB_ROOT_PASSWORD`: MariaDB root password for the container.
- `MARIADB_USER`: 'normal' MariaDB user, Freva will be connecting to the DB with
  this user name.
- `MARIADB_PASSWORD`: password for the 'normal' MariaDB user name.
- `MARIADB_DATABASE`: the name of the database where all Freva related tables
  are stored.

For the **Apache Solr** container consider the following environment variables:

- `CORE`: name of the standard core holding information about files (default:
   file)
- `SOLR_HEAP`: memory allocated for the solr process.
- `NUM_BACKUPS`: number of backups to keep. See backup for more details.


## Backup of data
If you added the `daily_backup.sh` files via a volume to the container you can
setup simple crontab to create backups on the *host* machine running
the container. A simple crontab example could like like this.

```
# m    h    dom   mon    dow      command
0      5    *     *      *        docker exec container-name bash -c /usr/local/bin/daily_backup
```
