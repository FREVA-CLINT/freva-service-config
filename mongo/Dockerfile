FROM docker.io/mongo:latest
ARG VERSION
LABEL org.opencontainers.image.version="$VERSION"

COPY --chmod=0755 init-mongo /usr/local/bin/start-mongo

ENV START_MONGO=true

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pymongo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["/usr/local/bin/start-mongo"]
