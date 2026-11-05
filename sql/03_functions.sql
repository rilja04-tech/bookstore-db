-- Аналитические функции на PL/pgSQL.
-- Все возвращают таблицу (RETURNS TABLE), поэтому вызываются как обычный SELECT:
--   SELECT * FROM get_most_ordered_books();

-- 1. Книги, которые заказывали чаще всего.
CREATE OR REPLACE FUNCTION get_most_ordered_books()
RETURNS TABLE (book_title VARCHAR, author VARCHAR, total_quantity BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT b.title,
           b.author,
           SUM(oi.quantity) AS total_quantity
    FROM order_items oi
    JOIN books b ON b.book_id = oi.book_id
    GROUP BY b.book_id, b.title, b.author
    ORDER BY total_quantity DESC;
END;
$$ LANGUAGE plpgsql STABLE;


-- 2. Средний чек заказов по жанрам.
CREATE OR REPLACE FUNCTION get_avg_check_by_genre()
RETURNS TABLE (genre VARCHAR, avg_check NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT b.genre,
           ROUND(AVG(o.total_amount), 2) AS avg_check
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN books b ON b.book_id = oi.book_id
    GROUP BY b.genre
    ORDER BY avg_check DESC;
END;
$$ LANGUAGE plpgsql STABLE;


-- 3. Средний чек и число заказов по сезонам.
CREATE OR REPLACE FUNCTION get_avg_check_by_season()
RETURNS TABLE (season VARCHAR, avg_check NUMERIC, order_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT CASE
               WHEN EXTRACT(MONTH FROM o.order_date) IN (6, 7, 8)   THEN 'Лето'
               WHEN EXTRACT(MONTH FROM o.order_date) IN (9, 10, 11) THEN 'Осень'
               WHEN EXTRACT(MONTH FROM o.order_date) IN (12, 1, 2)  THEN 'Зима'
               ELSE 'Весна'
           END::VARCHAR AS season,
           ROUND(AVG(o.total_amount), 2) AS avg_check,
           COUNT(*) AS order_count
    FROM orders o
    GROUP BY season
    ORDER BY CASE season
                 WHEN 'Зима'  THEN 1
                 WHEN 'Весна' THEN 2
                 WHEN 'Лето'  THEN 3
                 ELSE 4
             END;
END;
$$ LANGUAGE plpgsql STABLE;


-- 4. Рейтинг книг внутри возрастных групп покупателей (CTE + оконная функция).
CREATE OR REPLACE FUNCTION get_books_popularity_by_age_group()
RETURNS TABLE (age_group TEXT, book_title VARCHAR, popularity_rank BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH age_groups AS (
        SELECT CASE
                   WHEN DATE_PART('year', AGE(c.birth_date)) <= 12            THEN 'Дети'
                   WHEN DATE_PART('year', AGE(c.birth_date)) BETWEEN 13 AND 17 THEN 'Подростки'
                   WHEN DATE_PART('year', AGE(c.birth_date)) BETWEEN 18 AND 25 THEN 'Студенты'
                   WHEN DATE_PART('year', AGE(c.birth_date)) >= 60             THEN 'Пенсионеры'
                   ELSE 'Другие'
               END AS age_group,
               oi.book_id,
               SUM(oi.quantity) AS total_sold
        FROM customers c
        JOIN orders o ON o.customer_id = c.customer_id
        JOIN order_items oi ON oi.order_id = o.order_id
        GROUP BY 1, oi.book_id
    )
    SELECT ag.age_group,
           b.title,
           RANK() OVER (PARTITION BY ag.age_group ORDER BY ag.total_sold DESC) AS popularity_rank
    FROM age_groups ag
    JOIN books b ON b.book_id = ag.book_id
    ORDER BY ag.age_group, 3;
END;
$$ LANGUAGE plpgsql STABLE;
