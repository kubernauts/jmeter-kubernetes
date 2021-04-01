FROM kubernautslabs/jmeter-base:latest
LABEL maintainer="hao.shen@cognizant.com"
		
EXPOSE 1099 50000
		
ENTRYPOINT $JMETER_HOME/bin/jmeter-server \
-Dserver.rmi.localport=50000 \
-Dserver_port=1099 \
-Jserver.rmi.ssl.disable=true
