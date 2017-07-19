#!/bin/bash

# enable job control
set -m

# Export all environment variables from the env file
set -a
source /openwhisk_config/env

# Kafka expects KAFKA_PORT to just be the port while Kubernetes
# sets it to the entire tcp://host:port string
export KAFKA_PORT=$KAFKA_HOST_PORT

echo "Waiting for zookeeper to start"
while ! nc -z ${ZOOKEEPER_HOST} ${ZOOKEEPER_HOST_PORT}; do
  sleep 0.2
done

/start.sh &

echo "Waiting for kafka to start"
while ! nc -z localhost 9092; do
  sleep 0.2
done

unset JMX_PORT

echo "Creating completed topic"
kafka-topics.sh --create --if-not-exists --topic completed --replication-factor 1 --partitions 1 --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_HOST_PORT}

echo "Creating health topic"
kafka-topics.sh --create --if-not-exists --topic health --replication-factor 1 --partitions 1 --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_HOST_PORT}

echo "Creating invoker topics"
kafka-topics.sh --create --if-not-exists --topic invoker0 --replication-factor 1 --partitions 1 --zookeeper ${ZOOKEEPER_HOST}:${ZOOKEEPER_HOST_PORT}

fg
