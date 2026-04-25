-- ============================================================
-- test-date-predicate.sql
--
-- Воспроизводит панику "Failed to convert scalar to extension" на
-- DATE-колонке в vortex-формате. Вскрывается при q83 TPC-DS
-- (WHERE d_date IN (...)). Причина — VortexPredicateConverter отдавал
-- Literal.int32() для DATE, а vortex ожидает extension-scalar
-- (Literal.dateDays() / "vortex.date" DType).
--
-- Запуск:
--   ./run-sql.sh sql/test-date-predicate.sql
--
-- Без фикса: TM умирает native-panic-ом (non-unwinding abort).
-- С фиксом: SELECT возвращает count, TM живой.
-- ============================================================

USE CATALOG paimon_catalog;
USE demo4;

SET 'sql-client.execution.result-mode' = 'tableau';
SET 'execution.attached' = 'true';
SET 'execution.runtime-mode' = 'batch';

-- Таблица с DATE-колонкой. PK не обязателен — нужен только append + scan.
CREATE TABLE IF NOT EXISTS events_by_date_vortex (
  user_id BIGINT,
  dt      DATE,
  amount  DOUBLE
) WITH (
  'bucket'      = '4',
  'bucket-key'  = 'user_id',
  'file.format' = 'vortex'
);

-- Заливаем 90 строк с разбросом по датам вокруг 2000-06-30.
-- UNNEST раскрывает массив в таблицу — никаких оконок, чтобы избежать
-- "window rank requires order by" в batch-режиме.
INSERT INTO events_by_date_vortex
SELECT
  CAST(x AS BIGINT)                                           AS user_id,
  DATE '2000-06-01' + INTERVAL '1' DAY * CAST(MOD(x, 90) AS INT) AS dt,
  CAST(x AS DOUBLE) * 1.5                                     AS amount
FROM UNNEST(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
                  41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,
                  61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,
                  81,82,83,84,85,86,87,88,89,90]) AS t(x);

-- ── Триггерные предикаты ──
-- БЕЗ ФИКСА: rhs literal = raw int32, lhs column = extension "vortex.date".
-- vortex compare → as_extension() на rhs → panic → non-unwinding abort TM.

-- 1. Точное равенство по DATE — эквивалент q83 d_date = '2000-06-30'.
SELECT COUNT(*) AS eq_cnt
FROM events_by_date_vortex
WHERE dt = DATE '2000-06-30';

-- 2. IN с несколькими датами — буквально то что в q83 ломает.
SELECT COUNT(*) AS in_cnt
FROM events_by_date_vortex
WHERE dt IN (DATE '2000-06-15', DATE '2000-07-01', DATE '2000-08-15');

-- 3. Range — тоже проходит через extension-compare.
SELECT COUNT(*) AS range_cnt
FROM events_by_date_vortex
WHERE dt >= DATE '2000-07-01' AND dt <= DATE '2000-07-31';

-- 4. IS NULL (покрывается прошлым фиксом — typedNullLit → Literal.dateDays(null)).
SELECT COUNT(*) AS null_cnt
FROM events_by_date_vortex
WHERE dt IS NULL;
