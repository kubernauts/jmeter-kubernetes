#!/bin/bash -e

docker build --tag="kubernautslabs/jmeter-base:latest" -f Dockerfile-base .
docker build --tag="kubernautslabs/jmeter-master:latest" -f Dockerfile-master .
docker build --tag="kubernautslabs/jmeter-slave:latest" -f Dockerfile-slave .
docker build --tag="kubernautslabs/jmeter-reporter" -f Dockerfile-reporter .
