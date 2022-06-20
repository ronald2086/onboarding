FROM ubuntu:14.04

# Install 
RUN apt-get update
RUN apt-get upgrade -y

# install maven
ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN apt-get install -y curl

RUN apt-get -y upgrade && apt-get -y install software-properties-common && add-apt-repository ppa:openjdk-r/ppa -y && apt-get update

RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y git
RUN apt-get install -y rsync
RUN apt-get install -y python-pip
RUN pip install Django==1.6.1
RUN apt-get install -y gettext

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
ENV PATH "/usr/share/maven/bin:$PATH"

# Install NVM, Node, NPM
RUN mkdir -p /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 15.12.0

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash \
  && source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

RUN ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/node" "/usr/local/bin/node" \
  && ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" "/usr/local/bin/npm"

# Install npm-cli-login & npm-cli-adduser
RUN npm install -g npm-cli-login \
  && npm install -g npm-cli-adduser \
  && ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm-cli-login" "/usr/local/bin/npm-cli-login" \
  && ln -s "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm-cli-adduser" "/usr/local/bin/npm-cli-adduser"
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH


# trust Vault CA
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
COPY ci/vault_prod_ca.crt /root/vault_prod_ca.crt
RUN keytool -import -v -trustcacerts -noprompt -alias vault_prod -file /root/vault_prod_ca.crt -keystore ${JAVA_HOME}/jre/lib/security/cacerts -keypass changeit -storepass changeit
RUN npm config set cafile "/root/vault_prod_ca.crt"