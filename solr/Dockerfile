FROM solr:latest

LABEL maintainer="DRKZ-CLINT"
LABEL repository="https://gitlab.dkrz.de/freva/freva-service-config.git"
ENV CORE files
COPY --chown=solr:solr managed-schema.xml /opt/solr
COPY create_cores.sh /docker-entrypoint-initdb.d/
