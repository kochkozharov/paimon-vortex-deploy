docker exec -it sql-gateway \
        /opt/flink/bin/sql-client.sh gateway \
        --endpoint http://localhost:8083 \
        --init /opt/flink/init.sql