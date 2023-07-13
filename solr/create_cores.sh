#!/bin/bash

for this_core in  $CORE latest;do
    if [ ! -d "/var/solr/data/$this_core" ];then
        precreate-core $this_core
        cp /opt/solr/managed-schema.xml /var/solr/data/$this_core/conf/
        rm -rf /var/solr/data/$this_core/conf/synonyms.txt
        ln -s /opt/solr/synonyms.txt /var/solr/data/$this_core/conf/synonyms.txt
    fi
done
