#!/bin/bash -e
docker system prune

docker build --tag="kubernautslabs/jmeter-base:latest" -f jmeter-base.dockerfile .
docker build --tag="kubernautslabs/jmeter-master:latest" -f jmeter-master.dockerfile .
docker build --tag="kubernautslabs/jmeter-slave:latest" -f jmeter-slave.dockerfile .
