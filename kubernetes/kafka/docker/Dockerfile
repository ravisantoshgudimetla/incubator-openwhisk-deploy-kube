FROM ches/kafka:0.10.0.1

# Fix perms for Openshift
USER root
RUN chgrp -R 0 /kafka \
  && chmod -R g+rwX /kafka
USER kafka

COPY init.sh /init.sh
COPY server.properties /server.properties

CMD ["/init.sh"]
