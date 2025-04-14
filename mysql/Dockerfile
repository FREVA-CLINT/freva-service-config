FROM docker.io/mysql:9.0.1

ENV NUM_BACKUPS=7
ENV BACKUP_DIR=/var/lib/mysql/backup
COPY create_tables.sql /docker-entrypoint-initdb.d/0002_create_tables.sql
COPY --chmod=0755 reset_root_pw.sh /usr/local/bin/reset_root_pw
COPY --chmod=0755 daily_backup.sh /usr/local/bin/daily_backup
