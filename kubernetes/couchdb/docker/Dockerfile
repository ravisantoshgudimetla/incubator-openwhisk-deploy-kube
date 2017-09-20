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

RUN git clone https://github.com/apache/incubator-openwhisk /openwhisk

RUN chgrp -R 0 /usr/local/etc/couchdb \
  && chmod -R g+rwX /usr/local/etc/couchdb \
  && chgrp -R 0 /openwhisk/ansible/ \
  && chmod -R g+rwX /openwhisk/ansible/ \
  && chgrp -R 0 /usr/local/var/run/couchdb \
  && chmod -R g+rwX /usr/local/var/run/couchdb \
  && mkdir -p /.ansible \
  && chgrp -R 0 /.ansible \
  && chmod -R g+rwX /.ansible

COPY init.sh /init.sh

CMD ["/init.sh"]
