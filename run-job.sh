#!/bin/sh
JAR=${1:?Usage: ./run-job.sh JAR_PATH CLASS [job-args...]}
CLASS=${2:?CLASS required}
shift 2
docker cp "$JAR" jobmanager:/tmp/run-job.jar
docker exec jobmanager \
  /opt/flink/bin/flink run \
    --class "$CLASS" \
    /tmp/run-job.jar \
    "$@"
