-- Замер влияния индексов на планы запросов.
-- Создаёт отдельную таблицу на 200 000 строк, чтобы не трогать демо-данные,
-- и в конце её удаляет.
--
-- Запуск: psql -d bookstore -f queries/benchmark.sql
-- Результаты одного из прогонов записаны в queries/explain.md.

DROP TABLE IF EXISTS bench_orders;

CREATE TABLE bench_orders (
    id            SERIAL PRIMARY KEY,
    order_date    DATE        NOT NULL,
    total_amount  INT         NOT NULL,
    customer_name TEXT        NOT NULL
);

INSERT INTO bench_orders (order_date, total_amount, customer_name)
SELECT DATE '2023-01-01' + (g % 730),
       (g % 5000) + 100,
       'Клиент ' || (g % 5000)
FROM generate_series(1, 200000) AS g;

ANALYZE bench_orders;

\echo ''
\echo '=== 1. Диапазон дат БЕЗ индекса: ожидаем Seq Scan ==='
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31';

\echo ''
\echo '=== 2. Тот же запрос с btree-индексом по order_date ==='
CREATE INDEX idx_bench_date_btree ON bench_orders USING btree (order_date);
ANALYZE bench_orders;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31';

\echo ''
\echo '=== 3. То же, но с hash-индексом: для диапазона он бесполезен ==='
DROP INDEX idx_bench_date_btree;
CREATE INDEX idx_bench_date_hash ON bench_orders USING hash (order_date);
ANALYZE bench_orders;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31';

\echo ''
\echo '=== 4. hash-индекс на точном равенстве работает ==='
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE order_date = '2024-01-15';

DROP INDEX idx_bench_date_hash;

\echo ''
\echo '=== 5. Поиск без учёта регистра: обычный индекс не подходит ==='
CREATE INDEX idx_bench_name_plain ON bench_orders (customer_name);
ANALYZE bench_orders;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE lower(customer_name) = 'клиент 42';

\echo ''
\echo '=== 6. Функциональный индекс по lower(customer_name) ==='
DROP INDEX idx_bench_name_plain;
CREATE INDEX idx_bench_name_lower ON bench_orders (lower(customer_name));
ANALYZE bench_orders;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM bench_orders
WHERE lower(customer_name) = 'клиент 42';

\echo ''
DROP TABLE bench_orders;
