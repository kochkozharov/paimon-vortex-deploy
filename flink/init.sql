-- ─────────────────────────────────────────────────────────────────────────────
-- Paimon catalog backed by MinIO (S3-compatible storage, s3a:// scheme)
-- Run automatically via: sql-client.sh ... --init /opt/flink/init.sql
-- ─────────────────────────────────────────────────────────────────────────────

CREATE CATALOG IF NOT EXISTS paimon_catalog WITH (
  'type'      = 'paimon',
  'warehouse' = 's3a://warehouse/paimon'
);

USE CATALOG paimon_catalog;

-- Example: create a database and a simple Paimon table
-- CREATE DATABASE IF NOT EXISTS mydb;
-- USE mydb;
--
-- CREATE TABLE IF NOT EXISTS events (
--   event_time TIMESTAMP(3),
--   user_id    BIGINT,
--   action     STRING,
--   PRIMARY KEY (user_id, event_time) NOT ENFORCED
-- ) WITH (
--   'bucket'             = '2',
--   'changelog-producer' = 'input'
-- );
