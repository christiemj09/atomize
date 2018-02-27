-- Write a trigger in PL/pgSQL that:
-- 1. Takes a two-valued tuple from a view on INSERT
-- 2. Adds values to their own value tables, computing primary keys for them
-- 3. Adds the corresponding key pair into a two-valued relationship table between values.

/* Tables to hold data and a view to insert data into */

DROP TABLE IF EXISTS a CASCADE;
CREATE TABLE a (
    id SERIAL PRIMARY KEY,
    text TEXT UNIQUE
);

DROP TABLE IF EXISTS b CASCADE;
CREATE TABLE b (
    id SERIAL PRIMARY KEY,
    text TEXT UNIQUE
);

DROP TABLE IF EXISTS a_b CASCADE;
CREATE TABLE a_b (
    a INTEGER REFERENCES a(id),
    b INTEGER REFERENCES b(id)
);

CREATE OR REPLACE VIEW insert_a_b AS
    SELECT a.text AS a, b.text AS b
    FROM a, b, a_b
    WHERE a.id = a_b.a
      AND b.id = a_b.b;

/* A trigger function to break apart and store inserted values */

CREATE OR REPLACE FUNCTION trig_insert_a_b() RETURNS trigger AS
$$
DECLARE
    a_id INTEGER;
    b_id INTEGER;
BEGIN
    -- Conditionally insert into a
    SELECT id INTO a_id FROM a WHERE a.text = NEW.a;
    IF NOT FOUND THEN
        INSERT INTO a(text) VALUES (NEW.a) RETURNING id INTO a_id;
    END IF;

    -- Conditionally insert into b
    SELECT id INTO b_id FROM b WHERE b.text = NEW.b;
    IF NOT FOUND THEN
        INSERT INTO b(text) VALUES (NEW.b) RETURNING id INTO b_id;
    END IF;
    
    -- Unconditionally insert into a_b
    INSERT INTO a_b(a, b) VALUES (a_id, b_id);
    
    RETURN NEW;
END
$$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER trig_01_insert_a_b
INSTEAD OF INSERT ON insert_a_b
FOR EACH ROW EXECUTE PROCEDURE trig_insert_a_b();

/* Try doing some inserting, see if it handles it correctly */

INSERT INTO insert_a_b(a, b) VALUES
    ('Athabasca', 'Brevity'),
    ('Cerulean', 'Dardanelles'),
    ('Athabasca', 'Dardanelles');

-- See what's in your examples
SELECT 'a' AS label;
SELECT * FROM a;
SELECT 'b' AS label;
SELECT * FROM b;
SELECT 'a_b' AS label;
SELECT * FROM a_b;
SELECT 'insert_a_b' AS label;
SELECT * FROM insert_a_b;
