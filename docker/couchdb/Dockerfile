FROM couchdb:1.6

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y \
      git \
      curl \
      sudo \
      python-pip \
      python-dev \
      libffi-dev


# Workaround a bug in cffi and Debian Jesse that gets hit in ansible.sh
RUN pip install --upgrade cffi

RUN git clone https://github.com/openwhisk/openwhisk /openwhisk
RUN /openwhisk/tools/ubuntu-setup/ansible.sh

COPY couchdb-settings.ini /usr/local/etc/couchdb/local.d/whisk.ini
RUN chown couchdb:couchdb /usr/local/etc/couchdb/local.d/whisk.ini

COPY couchdb-init.sh /init.sh

ENTRYPOINT ["/bin/bash", "/init.sh"]
