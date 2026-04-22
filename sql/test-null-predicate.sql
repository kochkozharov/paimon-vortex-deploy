-- ============================================================
-- test-null-predicate.sql
--
-- Воспроизводит баг с untyped null-литералом в VortexPredicateConverter.
-- Без фикса: native panic (non-unwinding) → краш TM:
--   "Cannot compare different DTypes utf8? and null"
--   "Runtime dropped task without completing it, likely it panicked"
-- С фиксом: IsNull/IsNotNull пушдаунится с типизованным null → работает.
--
-- Запуск:
--   ./run-sql.sh sql/test-null-predicate.sql
-- ============================================================

-- Используем уже созданные init.sql таблицы (paimon_catalog.demo4).
USE CATALOG paimon_catalog;
USE demo4;

-- TABLEAU — обязательный result-mode для non-interactive SELECT.
SET 'sql-client.execution.result-mode' = 'tableau';
-- Attached — чтобы INSERT блокировал до завершения и не было race
-- с последующими SELECT-ами.
SET 'execution.attached' = 'true';

-- Залить данные, где часть action = NULL. datagen не умеет NULL-генерацию
-- напрямую, поэтому прогоняем через CASE.
SET 'execution.runtime-mode' = 'batch';

INSERT INTO events_vortex
SELECT
  user_id,
  event_time,
  -- Каждая 5-я строка — NULL. Это и триггерит IS NULL pushdown в scan.
  CASE WHEN MOD(user_id, 5) = 0 THEN CAST(NULL AS STRING) ELSE action END AS action,
  amount
FROM datagen_source;

-- ── Собственно триггерные запросы ──
-- БЕЗ ФИКСА каждый из этих селектов валит TM native-panic-ом.

-- 1. IS NULL по VARCHAR-колонке: utf8? vs untyped null → panic.
SELECT COUNT(*) AS null_actions
FROM events_vortex
WHERE action IS NULL;

-- 2. IS NOT NULL по той же колонке: то же самое поведение.
SELECT COUNT(*) AS non_null_actions
FROM events_vortex
WHERE action IS NOT NULL;

-- 3. IS NULL по BIGINT-колонке (в этой таблице user_id PK → NOT NULL,
--    но если был бы nullable, тоже ломалось бы — i64? vs null).
--    Оставлено в комментах как образец для воспроизведения на других
--    схемах.
-- SELECT COUNT(*) FROM events_vortex WHERE user_id IS NULL;
