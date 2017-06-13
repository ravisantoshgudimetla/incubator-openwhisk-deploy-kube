FROM ches/kafka:0.10.0.1

USER root

RUN chgrp -R 0 /kafka \
  && chmod -R g+rwX /kafka

USER kafka

COPY kafka-init.sh /init.sh

ENTRYPOINT ["/bin/bash", "/init.sh"]
