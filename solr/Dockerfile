FROM solr:latest

LABEL maintainer="DRKZ-CLINT"
LABEL repository="https://gitlab.dkrz.de/freva/freva-service-config.git"
ENV CORE files
COPY --chown=solr:solr managed-schema.xml /opt/solr
COPY create_core.sh /docker-entrypoint-initdb.d/
COPY daily_backup.sh /usr/local/bin/daily_backup
RUN chmod 755 /usr/local/bin/daily_backup
