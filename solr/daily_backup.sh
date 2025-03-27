#!/bin/bash
###############################################
# CREATE a daily backup of the two freva cores
curl -f -s "http://localhost:8983/solr/latest/replication?command=backup&numberToKeep=${NUM_BACKUPS}"
curl -f -s"http://localhost:8983/solr/${CORE}/replication?command=backup&numberToKeep=${NUM_BACKUPS}"
