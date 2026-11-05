-- Аналитические выборки: джойны, агрегаты, подзапросы.
-- Запуск: psql -d bookstore -f queries/analytics.sql

\echo '=== 1. Средний чек по магазинам (JOIN + GROUP BY) ==='
SELECT s.name,
       COUNT(o.order_id)            AS orders,
       ROUND(AVG(o.total_amount), 2) AS avg_check
FROM orders o
JOIN stores s ON s.store_id = o.store_id
GROUP BY s.name
ORDER BY avg_check DESC;


\echo '=== 2. Книги дороже средней цены по своему жанру (подзапрос в WHERE) ==='
SELECT b.title, b.genre, b.price
FROM books b
WHERE b.price > (
    SELECT AVG(b2.price) FROM books b2 WHERE b2.genre = b.genre
)
ORDER BY b.genre, b.price DESC;


\echo '=== 3. Клиенты, чьи заказы выше среднего (подзапрос в WHERE) ==='
SELECT c.name, o.order_date, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.total_amount > (SELECT AVG(total_amount) FROM orders)
ORDER BY o.total_amount DESC;


\echo '=== 4. Товары, которых на складе меньше 30 (фильтр + JOIN) ==='
SELECT s.name AS store, b.title, i.stock_quantity
FROM inventory i
JOIN stores s ON s.store_id = i.store_id
JOIN books b  ON b.book_id  = i.book_id
WHERE i.stock_quantity < 30
ORDER BY i.stock_quantity;


\echo '=== 5. Заказы за период в конкретном магазине (диапазон дат) ==='
SELECT o.order_id, o.order_date, o.total_amount
FROM orders o
JOIN stores s ON s.store_id = o.store_id
WHERE s.name = 'Книжный мир'
  AND o.order_date BETWEEN '2024-10-01' AND '2024-10-31';


\echo '=== 6. Самый дорогой заказ каждого клиента (коррелированный подзапрос) ==='
SELECT c.name, o.order_date, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.total_amount = (
    SELECT MAX(o2.total_amount) FROM orders o2 WHERE o2.customer_id = o.customer_id
)
ORDER BY o.total_amount DESC;


\echo '=== 7. Вызов аналитических функций ==='
SELECT * FROM get_most_ordered_books();
SELECT * FROM get_avg_check_by_genre();
SELECT * FROM get_avg_check_by_season();
SELECT * FROM get_books_popularity_by_age_group();
