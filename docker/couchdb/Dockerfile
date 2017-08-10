FROM couchdb:1.6

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y \
      git \
      curl \
      sudo \
      python-pip \
      python-dev \
      libffi-dev \
      libssl-dev \
      libuid-wrapper


# Workaround a bug in cffi and Debian Jesse that gets hit in ansible
RUN pip install --upgrade cffi

RUN pip install ansible==2.3.0.0

RUN git clone -b kube-container-openshift https://github.com/projectodd/incubator-openwhisk /openwhisk \
  && cd /openwhisk \
  && git checkout 21da7e5 \
  && cd /

COPY couchdb-settings.ini /usr/local/etc/couchdb/local.d/whisk.ini
RUN chown couchdb:couchdb /usr/local/etc/couchdb/local.d/whisk.ini

RUN chgrp -R 0 /usr/local/etc/couchdb/local.d \
  && chmod -R g+rwX /usr/local/etc/couchdb/local.d \
  && chgrp -R 0 /openwhisk/ansible/ \
  && chmod -R g+rwX /openwhisk/ansible/ \
  && chgrp -R 0 /usr/local/var/run/couchdb \
  && chmod -R g+rwX /usr/local/var/run/couchdb \
  && mkdir -p /.ansible \
  && chgrp -R 0 /.ansible \
  && chmod -R g+rwX /.ansible

COPY couchdb-init.sh /init.sh

ENTRYPOINT ["/bin/bash", "/init.sh"]
