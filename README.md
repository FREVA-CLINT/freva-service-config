# Freva services

This repository holds all definitions for Docker images to create all services
that are needed to run Freva in production and development mode.

Any changes to the configurations like MySQL table definitions or the apache solr
managed_schema.xml file should be done here.

An automated pipeline builds the images and pushes them to the DKRZ registry where
they can be pulled for usage in production or development mode.

## Using the build images
The images are automatically build and stored at a container registry. The urls
for the `docker pull` command or the corresponding `docker-compose` directive are:

- `registry.gitlab.dkrz.de/freva/freva-service-config/freva-solr:latest ` for the Freva *solr* image
- `registry.gitlab.dkrz.de/freva/freva-service-config/freva-db:latest` for the Freva *mysql* image

The containers automatically creating new MySQL tables (if not existing)
and solr cores (if not existing). The following environment variables should be
considered when starting the **MySQL** container:

- `MYSQL_ROOT_PASSWORD`: MySQL root password for the container.
- `MYSQL_USER`: 'normal' MySQL user, Freva will be connecting to the DB with this user name.
- `MYSQL_PASSWORD`: password for the 'normal' MySQL user name.
- `MYSQL_DATABASE`: the name of the database where all Freva related tables are stored.
- `NUM_BACKUPS`: number of backups to keep (default: 7). See backup for more details.
- `BACKUP_DIR`: location of the MySQL backup (default: /var/lib/mysql/backup). See backup for more details.

For the **apache solr** container consider the following environment variables:

- `CORE`: name of the standard core holding information about files (default: file)
- `SOLR_HEAP`: memory allocated for the solr process.
- `NUM_BACKUPS`: number of backups to keep. See backup for more details.


## Backup of data
Each of the above mentioned container ships with a backup script which can be
used in production mode. The backup scripts are located in `/usr/local/bin/daily_backup`
*within* the container. A simple crontab to create backups on the machine running
the container could look the following:

```
docker exec container-name /usr/local/bin/daily_backup
```
