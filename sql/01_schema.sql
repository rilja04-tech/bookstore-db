-- Схема книжного магазина: клиенты, книги, магазины, склад, заказы и продажи.
-- Запуск: psql -d bookstore -f sql/01_schema.sql

DROP TABLE IF EXISTS sale_items, sales, order_items, orders, inventory, stores, books, customers CASCADE;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    birth_date  DATE         NOT NULL
);

CREATE TABLE books (
    book_id      SERIAL PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    author       VARCHAR(255),
    genre        VARCHAR(100),
    price        INT CHECK (price > 0),
    target_group VARCHAR(50)
);

CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    name     VARCHAR(255) NOT NULL
);

CREATE TABLE inventory (
    inventory_id   SERIAL PRIMARY KEY,
    store_id       INT NOT NULL REFERENCES stores (store_id) ON DELETE CASCADE,
    book_id        INT NOT NULL REFERENCES books (book_id) ON DELETE CASCADE,
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    restock_date   DATE,
    UNIQUE (store_id, book_id)
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    store_id     INT  NOT NULL REFERENCES stores (store_id),
    customer_id  INT  REFERENCES customers (customer_id) ON DELETE SET NULL,
    order_date   DATE NOT NULL,
    total_amount INT  NOT NULL CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    book_id       INT NOT NULL REFERENCES books (book_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    price         INT NOT NULL CHECK (price > 0)
);

CREATE TABLE sales (
    sale_id      SERIAL PRIMARY KEY,
    store_id     INT  NOT NULL REFERENCES stores (store_id),
    sale_date    DATE NOT NULL,
    total_amount INT  NOT NULL CHECK (total_amount >= 0)
);

CREATE TABLE sale_items (
    sale_item_id SERIAL PRIMARY KEY,
    sale_id      INT NOT NULL REFERENCES sales (sale_id) ON DELETE CASCADE,
    book_id      INT NOT NULL REFERENCES books (book_id),
    quantity     INT NOT NULL CHECK (quantity > 0),
    price        INT NOT NULL CHECK (price > 0)
);

-- внешние ключи не индексируются автоматически, а по ним идут джойны
CREATE INDEX idx_order_items_order ON order_items (order_id);
CREATE INDEX idx_sale_items_sale   ON sale_items (sale_id);
CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_inventory_book    ON inventory (book_id);
