FROM redis:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends jq && \
    apt-get clean && \
    mkdir -p /redis/{config,data,bin,logs} && \
    chmod -R 2777 /redis && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 init-redis /redis/bin/init-redis
CMD ["/redis/bin/init-redis"]
