-- ============================================================
-- test-lance.sql
--
-- Базовая проверка работы Lance-формата в paimon: CREATE / INSERT / SELECT
-- + предикаты разных типов (DATE, INT, STRING, DECIMAL).
-- Цель — убедиться что lance в paimon-deploy локально живой,
-- прежде чем деплоить на кластер.
--
-- Запуск:
--   ./run-sql.sh sql/test-lance.sql
-- ============================================================

USE CATALOG paimon_catalog;
USE demo4;

SET 'sql-client.execution.result-mode' = 'tableau';
SET 'execution.attached' = 'true';
SET 'execution.runtime-mode' = 'batch';

-- Append-only таблица с разнотиповыми колонками: int/string/double/date/timestamp
CREATE TABLE IF NOT EXISTS events_lance (
  user_id    BIGINT,
  event_time TIMESTAMP(3),
  dt         DATE,
  action     STRING,
  amount     DOUBLE,
  price      DECIMAL(10, 2)
) WITH (
  'bucket'      = '4',
  'bucket-key'  = 'user_id',
  'file.format' = 'lance'
);

-- Залить 90 строк с разбросом по датам, разными action и numeric значениями.
INSERT INTO events_lance
SELECT
  CAST(x AS BIGINT)                                              AS user_id,
  CURRENT_TIMESTAMP                                              AS event_time,
  DATE '2000-06-01' + INTERVAL '1' DAY * CAST(MOD(x, 90) AS INT) AS dt,
  CASE WHEN MOD(x, 5) = 0 THEN CAST(NULL AS STRING)
       WHEN MOD(x, 3) = 0 THEN 'click'
       ELSE 'view' END                                           AS action,
  CAST(x AS DOUBLE) * 1.5                                        AS amount,
  CAST(x AS DECIMAL(10, 2)) * 100.50                             AS price
FROM UNNEST(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
                  41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,
                  61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,
                  81,82,83,84,85,86,87,88,89,90]) AS t(x);

-- ── Проверки read-path ──

-- 1. Полный count + min/max — базовая работа scan
SELECT COUNT(*) AS total, MIN(dt) AS min_dt, MAX(dt) AS max_dt FROM events_lance;

-- 2. Equality по DATE (то что в vortex ломалось без extension-fix)
SELECT COUNT(*) AS eq_date FROM events_lance WHERE dt = DATE '2000-06-30';

-- 3. IN по DATE (q83 паттерн)
SELECT COUNT(*) AS in_date FROM events_lance
WHERE dt IN (DATE '2000-06-15', DATE '2000-07-01', DATE '2000-08-15');

-- 4. Range по DATE
SELECT COUNT(*) AS range_date FROM events_lance
WHERE dt >= DATE '2000-07-01' AND dt <= DATE '2000-07-31';

-- 5. IS NULL / IS NOT NULL по STRING
SELECT COUNT(*) AS null_actions FROM events_lance WHERE action IS NULL;
SELECT COUNT(*) AS non_null_actions FROM events_lance WHERE action IS NOT NULL;

-- 6. STRING equality
SELECT COUNT(*) AS click_cnt FROM events_lance WHERE action = 'click';

-- 7. DECIMAL aggregation + filter
SELECT
  action,
  COUNT(*) AS cnt,
  AVG(price) AS avg_price,
  SUM(amount) AS total_amount
FROM events_lance
WHERE price > CAST(1000 AS DECIMAL(10, 2))
GROUP BY action
ORDER BY action;

-- 8. SELECT * с проекцией (column pruning)
SELECT user_id, dt, action FROM events_lance WHERE user_id BETWEEN 10 AND 15;
