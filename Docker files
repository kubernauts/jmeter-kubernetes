Docker images for the master and slaves nodes can be built using the following procedure.

First of all the jmeter base image needs to be created from the opend-jdk image, this will be used as reference while building the master and slaves images:

============JMETER BASE DOCKER FILE============

		FROM openjdk:8-jre-slim
		MAINTAINER Kubernauts-lab
		
		ARG JMETER_VERSION=4.0
		
		RUN apt-get clean && \
		apt-get update && \
		apt-get -qy install \
		wget \
		telnet \
		iputils-ping \
		unzip
		
		RUN   mkdir /jmeter \
		&& cd /jmeter/ \
		&& wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
		&& tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
		&& rm apache-jmeter-$JMETER_VERSION.tgz
		
		
		ADD jmeter-plugins/lib /jmeter/apache-jmeter-$JMETER_VERSION/lib
		
		ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/
		
		ENV PATH $JMETER_HOME/bin:$PATH

============Build, tag and push the base image============

		docker build --tag="kubernautslabs/jmeter-base:latest" -f Dockerfile-base .
		docker push kubernautslabs/jmeter-base:latest
    

============JMETER-MASTER DOCKER FILE============

		FROM kubernautslabs/jmeter-base:latest
		MAINTAINER Kubernauts-lab
		
		EXPOSE 60000

============Build, tag and push the master image============

		docker build --tag="kubernautslabs/jmeter-master:latest" -f Dockerfile-master .
		docker push kubernautslabs/jmeter-master:latest

================JMETER-SLAVES DOCKER FILE=====================
		FROM kubernautslabs/jmeter-base
		MAINTAINER Kubernauts-lab
		
		EXPOSE 1099 50000
		
		ENTRYPOINT $JMETER_HOME/bin/jmeter-server \
		-Dserver.rmi.ssl.disable=true \
		-Dserver.rmi.localport=50000 \
		-Dserver_port=1099


============Build, tag and push the slave image:================

		docker build --tag="kubernautslabs/jmeter-slave:latest" -f Dockerfile-slave .
		docker push kubernautslabs/jmeter-slave:latest

================JMETER-REPORTER DOCKER FILE=====================

		docker build --tag="kubernautslabs/jmeter-reporter" -f Dockerfile-reporter .
		docker push kubernautslabs/jmeter-reporter
