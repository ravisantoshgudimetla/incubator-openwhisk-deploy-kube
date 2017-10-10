FROM klaemo/couchdb:2.0

ADD http://ftp.us.debian.org/debian/pool/main/a/apt/apt-transport-https_1.0.9.8.4_amd64.deb /tmp/apt-transport-https_1.0.9.8.4_amd64.deb
ADD http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb /tmp/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb
RUN dpkg -i /tmp/libcurl3-gnutls_7.38.0-4+deb8u5_amd64.deb
RUN dpkg -i /tmp/apt-transport-https_1.0.9.8.4_amd64.deb

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
