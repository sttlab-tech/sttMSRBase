FROM cp.icr.io/cp/webmethods/integration/webmethods-microservicesruntime:11.1.0.0 AS builder

ARG WPM_TOKEN
ARG GIT_TOKEN

ADD --chown=1724:0 wpm /opt/softwareag/wpm
RUN chmod u+x /opt/softwareag/wpm/bin/wpm.sh
ENV PATH=/opt/softwareag/wpm/bin:$PATH

RUN /opt/softwareag/wpm/bin/wpm.sh install -ws https://packages.webmethods.io -wr supported -j $WPM_TOKEN -d /opt/softwareag/IntegrationServer WmE2EMIntegrationAgent:v10.15.0.10
RUN /opt/softwareag/wpm/bin/wpm.sh install -ws https://packages.webmethods.io -wr licensed -j $WPM_TOKEN -d /opt/softwareag/IntegrationServer WmJDBCAdapter:v10.3.4.20
RUN curl -o /opt/softwareag/IntegrationServer/packages/WmJDBCAdapter/code/jars/postgresql-42.7.4.jar https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
RUN /opt/softwareag/wpm/bin/wpm.sh install -u staillansag -p $GIT_TOKEN -r https://github.com/staillansag -d /opt/softwareag/IntegrationServer qdtFramework
RUN /opt/softwareag/IntegrationServer/bin/jcode.sh makeall qdtFramework

FROM redhat/ubi9

ENV JAVA_HOME=/opt/softwareag/jvm/jvm/ \
    JRE_HOME=/opt/softwareag/jvm/jvm/ \
    JDK_HOME=/opt/softwareag/jvm/jvm/ \
    PATH=$PATH:/opt/softwareag/wpm/bin

ENV JAVA_UHM_OPTS="-javaagent:./packages/WmE2EMIntegrationAgent/resources/agent/uha-apm-agent.jar=logging.dir=./logs/ -Xbootclasspath/a:./packages/WmE2EMIntegrationAgent/resources/agent/uha-apm-agent.jar"
ENV JAVA_CUSTOM_OPTS="${JAVA_CUSTOM_OPTS} ${JAVA_UHM_OPTS}"
ENV JAVA_UHM_LOG_OPTS="-Dlogback.configurationFile=./packages/WmE2EMIntegrationAgent/resources/agent/config/e2ecustomlogback.xml"
ENV JAVA_CUSTOM_OPTS="${JAVA_CUSTOM_OPTS} ${JAVA_UHM_LOG_OPTS}"	

RUN yum -y update ;\
    yum -y install \
        procps \
        shadow-utils \
        findutils \
        nmap-ncat \
        ;\
    yum clean all ;\
    rm -rf /var/cache/yum ;\
    useradd -u 1724 -m -g 0 -d /opt/softwareag sagadmin ;\
    chmod 770 /opt/softwareag

COPY --from=builder /opt/softwareag /opt/softwareag

USER 1724

EXPOSE 5555
EXPOSE 9999
EXPOSE 5553

ENTRYPOINT "/bin/bash" "-c" "/opt/softwareag/IntegrationServer/bin/startContainer.sh"