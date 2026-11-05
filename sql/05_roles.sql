-- Роли и права. Пароли здесь демонстрационные — в реальном проекте их
-- выдают через секреты, а не хранят в SQL-файле.
--
--   operator     — сотрудник магазина: только склад и чтение книг
--   generaluser  — полноценная работа с данными магазина
--   analyst      — только чтение и вызов аналитических функций
--   admin        — всё

DROP ROLE IF EXISTS operator, generaluser, analyst, admin;
DROP ROLE IF EXISTS operator_bd, user_bd, analyst_bd, admin_bd;

CREATE ROLE operator_bd;

CREATE ROLE user_bd;

CREATE ROLE analyst_bd;

CREATE ROLE admin_bd;

CREATE USER operator    WITH PASSWORD 'demo_pass_1' IN ROLE operator_bd;
CREATE USER generaluser WITH PASSWORD 'demo_pass_2' IN ROLE user_bd;
CREATE USER analyst     WITH PASSWORD 'demo_pass_3' IN ROLE analyst_bd;
CREATE USER admin       WITH PASSWORD 'demo_pass_4' IN ROLE admin_bd;

-- operator: принимает товар на склад и смотрит каталог
GRANT SELECT ON books TO operator_bd;
GRANT SELECT, INSERT, UPDATE ON inventory TO operator_bd;
GRANT USAGE, SELECT ON SEQUENCE inventory_inventory_id_seq TO operator_bd;

-- generaluser: работает с заказами и продажами
GRANT SELECT, INSERT, UPDATE, DELETE ON
      stores, books, customers, inventory, orders, order_items, sales, sale_items
    TO user_bd;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO user_bd;

-- analyst: только чтение и аналитические функции
GRANT SELECT ON
      stores, books, customers, inventory, orders, order_items, sales, sale_items
    TO analyst_bd;
GRANT EXECUTE ON FUNCTION
      get_most_ordered_books(),
      get_avg_check_by_genre(),
      get_avg_check_by_season(),
      get_books_popularity_by_age_group()
    TO analyst_bd;

-- admin: полный доступ к данным
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_bd;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_bd;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_bd;
