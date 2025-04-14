FROM docker.io/solr:latest

ARG VERSION
LABEL org.opencontainers.image.version="$VERSION"
ENV CORE=files
ENV NUM_BACKUPS=7


COPY --chmod=0755 daily_backup.sh /usr/local/bin/daily_backup
COPY --chmod=0755 create_cores.sh /usr/local/bin/create-freva-cores
COPY --chmod=0755 start-freva-solr.sh /usr/local/bin/start-freva-solr

COPY managed-schema.xml /opt/solr/managed-schema.xml
COPY synonyms.txt /opt/solr/synonyms.txt

CMD ["/usr/local/bin/start-freva-solr"]
