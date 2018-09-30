#!/usr/bin/env bash
#Create multiple Jmeter ingress on an existing kubernetes deployment
#Started On January 23, 2018

echo

echo "Enter the name of the namespace that will be used to create the ingress"
read tenant
echo

openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 365 -out tls.crt

kubectl -n $tenant create secret generic traefik-cert --from-file=tls.crt --from-file=tls.key

kubectl -n $tenant create configmap traefik-conf --from-file=traefik.toml

kubectl -n $tenant create -f traefik-rbac.yaml

kubectl -n $tenant create -f traefik.yaml

kubectl -n $tenant create -f ingress.yaml
