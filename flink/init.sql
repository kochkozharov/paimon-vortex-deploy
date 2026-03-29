CREATE CATALOG IF NOT EXISTS paimon_catalog WITH (
  'type'      = 'paimon',
  'warehouse' = 's3a://warehouse/paimon'
);

USE CATALOG paimon_catalog;

CREATE DATABASE IF NOT EXISTS demo3;
USE demo3;

CREATE TABLE IF NOT EXISTS events_parquet (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE,
  PRIMARY KEY (user_id, event_time) NOT ENFORCED
) WITH (
  'bucket'       = '4',
  'file.format'  = 'parquet'
);

CREATE TABLE IF NOT EXISTS events_vortex (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE,
  PRIMARY KEY (user_id, event_time) NOT ENFORCED
) WITH (
  'bucket'       = '4',
  'file.format'  = 'vortex'
);

CREATE TEMPORARY TABLE datagen_source (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE
) WITH (
  'connector'                  = 'datagen',
  'number-of-rows'             = '100',
  'fields.user_id.min'         = '1',
  'fields.user_id.max'         = '50',
  'fields.event_time.max-past' = '600000',
  'fields.action.length'       = '1',
  'fields.amount.min'          = '1.0',
  'fields.amount.max'          = '500.0'
);
