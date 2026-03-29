SET 'sql-client.execution.result-mode' = 'tableau';
SET 'execution.runtime-mode' = 'batch';

CREATE TEMPORARY TABLE datagen_large (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  action     STRING,
  amount     DOUBLE
) WITH (
  'connector'                  = 'datagen',
  'number-of-rows'             = '500000',
  'fields.user_id.min'         = '1',
  'fields.user_id.max'         = '10000',
  'fields.event_time.max-past' = '86400000',
  'fields.action.length'       = '1',
  'fields.amount.min'          = '1.0',
  'fields.amount.max'          = '500.0'
);

INSERT INTO events_parquet SELECT * FROM datagen_large;
INSERT INTO events_vortex  SELECT * FROM datagen_large;

-- warmup
SELECT COUNT(*) FROM events_parquet;
SELECT COUNT(*) FROM events_vortex;

-- TEST1
SELECT 'parquet' AS fmt, action, COUNT(*) AS cnt, ROUND(AVG(amount), 2) AS avg_amount
FROM events_parquet GROUP BY action;

SELECT 'vortex'  AS fmt, action, COUNT(*) AS cnt, ROUND(AVG(amount), 2) AS avg_amount
FROM events_vortex  GROUP BY action;

-- TEST2
SELECT 'parquet' AS fmt, COUNT(*) AS cnt FROM events_parquet WHERE amount BETWEEN 100.0 AND 150.0;
SELECT 'vortex'  AS fmt, COUNT(*) AS cnt FROM events_vortex  WHERE amount BETWEEN 100.0 AND 150.0;

TRUNCATE TABLE events_parquet;
TRUNCATE TABLE events_vortex;
