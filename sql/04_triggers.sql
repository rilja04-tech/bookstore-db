-- Триггеры.
--
-- Каскадное удаление связанных строк здесь работает через ON DELETE CASCADE на внешних
-- ключах (см. 01_schema.sql) — это дешевле и надёжнее, чем триггер, который удаляет
-- связанные записи вручную. Триггер ниже решает другую задачу: подставляет значения
-- по умолчанию, когда их не передали.

CREATE SEQUENCE IF NOT EXISTS author_name_seq START 1;

CREATE TABLE IF NOT EXISTS authors (
    author_id   SERIAL PRIMARY KEY,
    name        VARCHAR(255),
    city        VARCHAR(255),
    circulation INT
);

CREATE OR REPLACE FUNCTION before_insert_author()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.name IS NULL THEN
        NEW.name := 'Avtor' || NEXTVAL('author_name_seq');
    END IF;

    IF NEW.city IS NULL THEN
        NEW.city := 'Samara';
    END IF;

    IF NEW.circulation IS NULL OR NEW.circulation <= 50 THEN
        IF NEW.city = 'Samara' THEN
            NEW.circulation := 50;
        ELSE
            NEW.circulation := 0;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_before_insert_author ON authors;

CREATE TRIGGER trg_before_insert_author
BEFORE INSERT ON authors
FOR EACH ROW
EXECUTE FUNCTION before_insert_author();
