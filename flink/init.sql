-- ─────────────────────────────────────────────────────────────────────────────
-- Paimon catalog backed by MinIO (S3-compatible storage, s3a:// scheme)
-- Run automatically via: sql-client.sh ... --init /opt/flink/init.sql
-- ─────────────────────────────────────────────────────────────────────────────

CREATE CATALOG IF NOT EXISTS paimon_catalog WITH (
  'type'      = 'paimon',
  'warehouse' = 's3a://warehouse/paimon'
);

USE CATALOG paimon_catalog;

CREATE DATABASE IF NOT EXISTS demo;
USE demo;

-- Paimon table for storing generated events
CREATE TABLE IF NOT EXISTS events (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE,
  PRIMARY KEY (user_id, event_time) NOT ENFORCED
) WITH (
  'bucket' = '2'
);

-- Temporary datagen source (100 rows, bounded)
CREATE TEMPORARY TABLE datagen_source (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE
) WITH (
  'connector'                        = 'datagen',
  'number-of-rows'                   = '100',
  'fields.user_id.min'               = '1',
  'fields.user_id.max'               = '50',
  'fields.event_time.max-past'       = '600000',
  'fields.action.length'             = '6',
  'fields.amount.min'                = '1.0',
  'fields.amount.max'                = '500.0'
);
