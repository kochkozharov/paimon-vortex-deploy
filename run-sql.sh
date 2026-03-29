#!/bin/sh
FILE=${1:?Usage: ./run-sql.sh sql/benchmark.sql}
docker cp "$FILE" sql-gateway:/tmp/run.sql
docker exec -it sql-gateway \
  /opt/flink/bin/sql-client.sh gateway \
    --endpoint http://localhost:8083 \
    --init /opt/flink/init.sql \
    -f /tmp/run.sql
