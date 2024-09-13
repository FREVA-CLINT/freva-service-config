#!/bin/bash

if ! bin/elasticsearch-plugin list | grep -q analysis-icu; then
  bin/elasticsearch-plugin install analysis-icu
fi

exec bin/elasticsearch

echo "Waiting for Elasticsearch to start..."
until curl -s http://localhost:9200 >/dev/null; do
  sleep 1
done

curl -X PUT "http://localhost:9200/_index_template/shared-template" \
     -H "Content-Type: application/json" \
     --data-binary @/usr/share/elasticsearch/config/index_template.json
wait