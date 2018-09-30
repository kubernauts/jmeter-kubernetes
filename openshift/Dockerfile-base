FROM fabric8/s2i-java
MAINTAINER kubernautslabs
		
# ARG JMETER_VERSION=3.3
ARG JMETER_VERSION=4.0

USER root

# RUN addgroup --group jmeter
# RUN adduser --disabled-password --gecos '' jmeter
# RUN adduser jmeter -g jmeter

# https://stackoverflow.com/questions/27701930/add-user-to-docker-container

# RUN useradd -d /jmeter/apache-jmeter-$JMETER_VERSION/ -ms /bin/bash -g root -p jboss jboss
# USER jboss


RUN yum -y update && \
yum -y install \
wget \
telnet \
iputils-ping \
unzip

RUN   mkdir /jmeter \
&& cd /jmeter/ \
&& wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
&& tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
&& rm apache-jmeter-$JMETER_VERSION.tgz

WORKDIR /jmeter

# Set directory and file permissions (not sure if that's fine)
RUN chown -R jboss:root /jmeter  \
    && chmod -R "g+rwx,o+x" /jmeter


USER jboss

# ADD jmeter-plugins/lib /jmeter/apache-jmeter-$JMETER_VERSION/lib
		
ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/
		
ENV PATH $JMETER_HOME/bin:$PATH
