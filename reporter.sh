#!/usr/bin/env bash
#Create graphana reporter within an existing kuberntes namespace
#Started On March 3, 2021

working_dir=`pwd`
tenant=`awk '{print $NF}' $working_dir/tenant_export`
kubectl create -n $tenant -f $working_dir/jmeter_grafana_reporter.yaml
