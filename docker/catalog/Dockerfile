FROM centos:7

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN yum update -y \
  && yum install -y epel-release \
  && yum repolist \
  && yum install -y curl wget git openssl nss_wrapper gettext npm zip \
  && yum clean all

# Clone our branch of OpenWhisk
RUN git clone -b kube-container-openshift https://github.com/projectodd/incubator-openwhisk /openwhisk \
  && cd /openwhisk \
  && git checkout f7bfe7e \
  && cd /

# Clone the default OpenWhisk catalog
RUN git clone https://github.com/apache/incubator-openwhisk-catalog.git /openwhisk-catalog \
  && cd /openwhisk-catalog \
  && git checkout 5414efc \
  && cd /

ENV OPENWHISK_HOME /openwhisk

# Install wsk binary
RUN curl -L https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz | tar xz && mv wsk /openwhisk/bin/wsk

# Ensure we can write to needed directories on OpenShift
RUN chgrp -R 0 /openwhisk \
  && chmod -R g+rwX /openwhisk \
  && mkdir -p /openwhisk-catalog \
  && chgrp -R 0 /openwhisk-catalog \
  && chmod -R g+rwX /openwhisk-catalog \
  && mkdir -p /.npm \
  && chgrp -R 0 /.npm \
  && chmod -R g+rwX /.npm

COPY catalog-init.sh /init.sh
COPY passwd.template /passwd.template

ENTRYPOINT ["/bin/bash", "/init.sh"]
