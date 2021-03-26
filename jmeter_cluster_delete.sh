#!/usr/bin/env bash
#Delete multiple Jmeter namespaces on an existing kuberntes cluster
#Started On January 23, 2018

working_dir=`pwd`

echo "checking if kubectl is present"

if ! hash kubectl 2>/dev/null
then
    echo "'kubectl' was not found in PATH"
    echo "Kindly ensure that you can acces an existing kubernetes cluster via kubectl"
    exit
fi

kubectl version --short

echo "Current list of namespaces on the kubernetes cluster:"

echo

kubectl get namespaces | grep -v NAME | awk '{print $1}'

echo

echo "Enter the name of the existing tenant unique name, this will be used to delete the namespace"
read tenant
echo

#Check If namespace exists

kubectl get namespace $tenant > /dev/null 2>&1

if [ $? !-eq 0 ]
then
  echo "Namespace $tenant exist, this namespace will be deleted "
  echo "Current list of namespaces on the kubernetes cluster"
  sleep 2

#  kubectl get namespaces | grep -v NAME | awk '{print $1}'
  exit 1
fi

echo
echo "Deleting Namespace: $tenant"

kubectl delete namespace $tenant

echo "Namespace $tenant has been deleted"

echo

echo "Number of worker nodes on this cluster is " $nodes

echo

echo "Printout Of the $tenant Objects"

echo

kubectl get -n $tenant all

echo namespace = $tenant > $working_dir/tenant_export
