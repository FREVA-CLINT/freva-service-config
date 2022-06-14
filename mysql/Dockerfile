FROM mysql:latest

LABEL maintainer="DRKZ-CLINT"
LABEL repository="https://gitlab.dkrz.de/freva/freva-service-config.git"
ENV NUM_BACKUPS=7
ENV BACKUP_DIR=/var/lib/mysql/backup
COPY create_tables.sql /docker-entrypoint-initdb.d/0002_create_tables.sql
COPY daily_backup.sh /usr/local/bin/daily_backup
RUN chmod 755 /usr/local/bin/daily_backup
