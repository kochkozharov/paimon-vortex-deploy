#!/usr/bin/env bash
# Startup wrapper for Flink SQL Gateway.
# Updates jobmanager address in config (without creating duplicates),
# then launches the gateway in the foreground.
set -euo pipefail

CONF=/opt/flink/conf/config.yaml

if [ -n "${JOB_MANAGER_RPC_ADDRESS:-}" ]; then
    sed -i "s|^jobmanager.rpc.address:.*|jobmanager.rpc.address: \"${JOB_MANAGER_RPC_ADDRESS}\"|" "$CONF"
fi

exec /opt/flink/bin/sql-gateway.sh start-foreground
