FROM ubuntu:14.04
MAINTAINER Willy Morin <willy.morin@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'root:root' | chpasswd

RUN apt-get update && apt-get -y dist-upgrade && apt-get autoclean

RUN apt-get -y install python-software-properties software-properties-common

RUN add-apt-repository "deb http://archive.ubuntu.com/ubuntu precise main universe" && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu precise-updates universe" && \
    add-apt-repository -y ppa:webupd8team/java

RUN apt-get update

#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections

RUN apt-get install -y \
    less \
    ntp \
    net-tools \
    inetutils-ping \
    curl \
    git \
    unzip \
    telnet \
    supervisor \
    openssh-server \
    mysql-server \
    oracle-java7-installer

RUN mkdir -p /var/log/supervisor && \
    mkdir /var/run/sshd && \
    sed -i -e "s|127.0.0.1|0.0.0.0|g" -e "s|max_allowed_packet.*|max_allowed_packet = 1024M|" /etc/mysql/my.cnf

CMD ["/usr/bin/supervisord", "-n"]

#Azkaban Web Server
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.5.0/azkaban-web-server-2.5.0.tar.gz && \
    tar xf azkaban-web-server-*.tar.gz && \
    rm azkaban-web-server-*.tar.gz

#Azkaban Executor Server
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.5.0/azkaban-executor-server-2.5.0.tar.gz && \
    tar xf azkaban-executor-server-*.tar.gz && \
    rm azkaban-executor-server-*.tar.gz

#Azkaban MySQL scripts
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.5.0/azkaban-sql-script-2.5.0.tar.gz && \
    tar xf azkaban-sql-script-*.tar.gz && \
    ls -l && rm azkaban-sql-script-*.tar.gz

#MySQL JDBC driver
RUN wget -O /azkaban-executor-2.5.0/extlib/mysql-connector-java-5.1.35.jar "http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.35/mysql-connector-java-5.1.35.jar"
RUN ls /azkaban-executor-2.5.0

RUN ls -l /
#Configure
RUN mkdir /tmp/web && sed -i -e "s|^tmpdir=|tmpdir=/tmp/web|" -e "s|&||" /azkaban-web-2.5.0/bin/azkaban-web-start.sh && \
    mkdir /tmp/executor && sed -i -e "s|^tmpdir=|tmpdir=/tmp/executor|" -e "s|&||" /azkaban-executor-2.5.0/bin/azkaban-executor-start.sh && \
    cd azkaban-2.5.0 && \
    keytool -keystore keystore -alias jetty -genkey -keyalg RSA -keypass password -storepass password -dname "CN=Unknown, OU=Unknown, O=Unknown,L=Unknown, ST=Unknown, C=Unknown"

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Init MySql
ADD mysql.sql mysql.sql
RUN mysqld & sleep 3 && \
    mysql < mysql.sql && \
    mysql --database=azkaban2 < /azkaban-2.5.0/create-all-sql-2.5.0.sql && \
    mysqladmin shutdown

EXPOSE 22 8443

