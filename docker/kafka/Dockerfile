FROM ches/kafka:0.10.0.1

USER root

RUN chgrp -R 0 /kafka \
  && chmod -R g+rwX /kafka

USER kafka

COPY init.sh /init.sh
COPY server.properties.template /kafka/config/server.properties.template

ENTRYPOINT ["/bin/bash", "/init.sh"]
