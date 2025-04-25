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
       SERVICE=${SERVICE}

WORKDIR /tmp/app
COPY . /tmp/app

RUN set -xue && \
 ls -l /tmp/app/${SERVICE} && ls -l ${SERVICE} && \
 mkdir -p ${MAMBA_ROOT_PREFIX}/etc/profile.d  /data/config /data/db /data/logs &&\
 cp docker-scripts/vars.sh ${MAMBA_ROOT_PREFIX}/etc/profile.d/freva-rest-server.sh &&\
 cp ${SERVICE}/init-${SERVICE} /usr/local/bin/start-service &&\
 cp docker-scripts/healthchecks.sh /usr/local/bin/healthchecks &&\
 cp ${SERVICE}/*.txt /data/config/ 2> /dev/null || true && \
 cp ${SERVICE}/*.xml /data/config/ 2> /dev/null || true && \
 cp ${SERVICE}/*.sql /data/config/ 2> /dev/null || true && \
 rm -f /data/config/requirements.txt && \
 cp ${SERVICE}/daily_backup.sh /usr/local/bin/daily_backup || true &&\
 chmod +x /usr/local/bin/daily_backup 2> /dev/null || true &&\
 chmod +x /usr/local/bin/start-service /usr/local/bin/healthchecks

RUN  set -eux && \
     micromamba install -c conda-forge -q -y --override-channels -f $SERVICE/requirements.txt && \
     micromamba clean -y -i -t -l -f && \
     mkdir -p /data/{db,logs,config} && \
     rm -rf /tmp/app

WORKDIR /tmp
CMD ["/usr/local/bin/start-service"]
