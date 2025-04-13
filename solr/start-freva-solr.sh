#!/bin/bash
set -euo pipefail

# Start Solr in the background
solr-precreate temp && solr start -f &

# Wait for Solr to be up
echo "Waiting for Solr to be available..."
until curl -s "http://localhost:8983/solr/admin/ping" | grep -q '"status":"OK"'; do
  sleep 1
done
echo "Solr is ready."

# Create the Freva cores
echo "Creating Freva Solr cores..."
/usr/local/bin/create-freva-cores

# Tail logs to keep the container running
echo "Tailing Solr logs..."
tail -f /var/solr/logs/solr.log
