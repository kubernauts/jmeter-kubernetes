#!/usr/bin/env bash

working_dir=`pwd`

#Get namesapce variable
# tenant=`awk '{print $NF}' $working_dir/tenant_export`

## Create jmeter database automatically in Influxdb

echo "Creating Influxdb jmeter Database"

##Wait until Influxdb Deployment is up and running
##influxdb_status=`oc get po -n $tenant | grep influxdb-jmeter | awk '{print $2}' | grep Running

influxdb_pod=`oc get pod | grep influxdb | awk '{print $1}'`
oc exec -ti $influxdb_pod -- influx -execute 'CREATE DATABASE jmeter'

## make sure the db is created

# $ oc rsh $influxdb_pod 

oc exec -ti $influxdb_pod -- influx -execute 'SHOW DATABASES'

## Create the influxdb datasource in Grafana

echo "Creating the Influxdb data source"
grafana_pod=`oc get pod | grep jmeter-grafana | awk '{print $1}'`

## Make load test script in Jmeter master pod executable

#Get Master pod details

master_pod=`oc get pod | grep jmeter-master | awk '{print $1}'`

# oc exec -ti $master_pod -- cp -r /load_test /jmeter/load_test

# oc exec -it $master_pod -- /bin/bash -- chmod 755 /jmeter/load_test

##oc cp $working_dir/influxdb-jmeter-datasource.json -n $tenant $grafana_pod:/influxdb-jmeter-datasource.json

oc exec -it $grafana_pod -- curl 'http://admin:admin@127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"jmeterdb","type":"influxdb","url":"http://jmeter-influxdb:8086","access":"proxy","isDefault":true,"database":"jmeter","user":"admin","password":"admin"}'
