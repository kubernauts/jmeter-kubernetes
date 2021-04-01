#!/usr/bin/env bash

working_dir=`pwd`

#Get namesapce variable
tenant=`awk '{print $NF}' $working_dir/tenant_export`

echo "Creating Reporter on namespace $tenant"
kubectl -n $tenant create -f jmeter_grafana_reporter.yaml
