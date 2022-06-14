#!/bin/bash

for core in  $CORE latest;do
    if [ ! -d "/var/solr/data/$core" ];then
        precreate-core $core
        cp /opt/solr/managed-schema.xml /var/solr/data/$core/conf/
    fi
done
