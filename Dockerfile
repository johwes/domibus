
FROM registry.access.redhat.com/ubi8 as builder
ARG GS_VERSION=5.0.1
ARG WAR_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/public/eu/domibus/domibus-distribution/${GS_VERSION}/domibus-distribution-${GS_VERSION}-tomcat-full.zip
ARG CONF_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/public/eu/domibus/domibus-distribution/${GS_VERSION}/domibus-distribution-${GS_VERSION}-sample-configuration-and-testing.zip

#https://ec.europa.eu/cefdigital/artifact/content/repositories/public/eu/domibus/domibus-distribution/4.2.7/domibus-distribution-4.2.7-tomcat-full.zip

WORKDIR /tmp

RUN mkdir /tmp/domibus && curl -L ${WAR_URL} -o /tmp/domibus.zip && dnf -y install unzip && unzip /tmp/domibus.zip -d /tmp/domibus
RUN mkdir /tmp/domibus_conf && curl -L ${CONF_URL} -o /tmp/conf.zip  && unzip -o /tmp/conf.zip -d /tmp/domibus_conf && cp -R /tmp/domibus_conf/conf /tmp/domibus/domibus/
RUN sed -i 's/domibus.database.serverName=localhost/domibus.database.serverName=mysql/g' /tmp/domibus/domibus/conf/domibus/domibus.properties
COPY mysql-connector-java-8.0.30.jar /tmp/domibus/domibus/lib/
COPY setenv.sh /tmp/domibus/domibus/bin/
RUN chown -R 185:0 /tmp/domibus
RUN chmod -R 775 /tmp/domibus

# FROM registry.redhat.io/jboss-webserver-5/jws56-openjdk11-openshift-rhel8@sha256:ec10836f2ec107401e1586e7084e68615c1598c23e7564a6bed6dc2f37535255
FROM registry.redhat.io/jboss-webserver-5/jws56-openjdk11-openshift-rhel8@sha256:7388b0e0d46767158bde19c70987a7b58e3761a81a4c03d6268bc9bd9777cd00
COPY --from=builder /tmp/domibus/* /opt/jws-5.6/tomcat/webapps/
RUN chmod -R 775 /opt/jws-5.6/tomcat/webapps
