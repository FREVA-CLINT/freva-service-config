FROM docker.io/mambaorg/micromamba
USER root
ARG SERVICE
ARG VERSION
LABEL org.freva.service="$SERVICE"
LABEL org.opencontainers.image.authors="DRKZ-CLINT"
LABEL org.opencontainers.image.source="https://github.com/FREVA-CLINT/freva-nextgen/freva-rest"
LABEL org.opencontainers.image.version="$VERSION"
ENV    PYTHONUNBUFFERED=1 \
       IN_DOCKER=1 \
       SERVICE=${SERVICE} \
       PATH=/opt/conda/bin:${PATH}

WORKDIR /tmp/app
COPY . /tmp/app

RUN set -xue && \
 ls -l /tmp/app/${SERVICE} && ls -l ${SERVICE} && \
 cp docker-scripts/entrypoint.sh /usr/local/bin/ &&\
 chmod +x /usr/local/bin/entrypoint.sh && \
 cp ${SERVICE}/init-${SERVICE} /usr/local/bin/start-service &&\
 mkdir -p /data/{db,logs,config} /backup && \
 cp docker-scripts/healthchecks.sh /usr/local/bin/healthchecks &&\
 cp ${SERVICE}/*.txt /data/config/ 2> /dev/null || true && \
 cp ${SERVICE}/*.xml /data/config/ 2> /dev/null || true && \
 cp ${SERVICE}/*.sql /data/config/ 2> /dev/null || true && \
 cp ${SERVICE}/*.{types,j2,html,gif} /data/config/ 2> /dev/null || true && \
 rm -f /data/config/requirements.txt && \
 cp ${SERVICE}/daily_backup.sh /usr/local/bin/daily_backup || true &&\
 chmod +x /usr/local/bin/daily_backup 2> /dev/null || true &&\
 chmod +x /usr/local/bin/start-service /usr/local/bin/healthchecks

RUN set -eu \
     && for user in sync news uucp irc list lp games gnats ftp man proxy operator talk nobody _apt;do\
       deluser $user 2> /dev/null || true;\
     done \
     && delgroup mambauser || true \
     && rm -rf /home/mambauser || true \
     && delgroup nogroup || true \
     && addgroup --system --gid 65534 nobody || true \
     && adduser \
    --system \
    --uid 65534 \
    --gid 65534 \
    --no-create-home \
    --disabled-password \
    --shell /usr/sbin/nologin \
    nobody

RUN  set -eux && \
     micromamba install -c conda-forge -q -y --override-channels -f $SERVICE/requirements.txt && \
     micromamba clean -q -y -i -t -l -f && \
     chmod 1777 -R /data /backup && \
     rm -rf /tmp/app

WORKDIR /data
CMD ["/usr/local/bin/start-service"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
