-- Examples of how to use triggers to update tables underlying a view.

DROP TABLE IF EXISTS country CASCADE;

CREATE TABLE country (
    id INTEGER PRIMARY KEY,
    name TEXT
);

DROP TABLE IF EXISTS fact CASCADE;

CREATE TABLE fact (
    id INTEGER PRIMARY KEY,
    country_id INTEGER REFERENCES country(id),
    text TEXT
);

INSERT INTO country(id, name) VALUES
    (1, 'France'),
    (2, 'Germany'),
    (3, 'Italy'),
    (4, 'Spain');

INSERT INTO fact(id, country_id, text) VALUES
    (1, 1, 'speaks French'),
    (2, 1, 'is west of Germany'),
    (3, 1, 'was home to the Gauls'),
    (4, 2, 'is east of France'),
    (5, 2, 'drinks beer'),
    (6, 3, 'has Rome as a capital'),
    (7, 3, 'is west of the Adriatic Sea'),
    (8, 3, 'is south of the Alps'),
    (9, 4, 'speaks Spanish');

CREATE OR REPLACE VIEW country_fact AS
    SELECT c.id AS country_id,
           c.name AS country_name,
           f.id AS fact_id,
           f.text AS fact
    FROM country c, fact f
    WHERE c.id = f.country_id;

-- See what's in your examples
SELECT 'country' AS label;
SELECT * FROM country;
SELECT 'fact' AS label;
SELECT * FROM fact;
SELECT 'country_fact' AS label;
SELECT * FROM country_fact;

-- Trigger function to manage modifications on view
CREATE OR REPLACE FUNCTION trig_country_fact_ins_upd_del() RETURNS trigger AS
$$
BEGIN
IF (TG_OP = 'DELETE') THEN
    -- Assume a delete on the view is for fact deletion
    DELETE FROM fact AS f
    WHERE f.id = OLD.fact_id;
    RETURN OLD;
END IF;
IF (TG_OP = 'INSERT') THEN
    -- Assume country already exists; use this to associate a new fact with a country
    INSERT INTO fact(id, country_id, text) SELECT NEW.fact_id, NEW.country_id, NEW.fact;
    RETURN NEW;
END IF;
IF (TG_OP = 'UPDATE') THEN
    -- Update all necessary data to make the updated record appear in the view
    UPDATE country
    SET id = NEW.country_id, name = NEW.country_name
    WHERE id = OLD.country_id;
    UPDATE fact
    SET id = NEW.fact_id, text = NEW.fact
    WHERE id = OLD.fact_id;
    RETURN NEW;
    -- Note: There was something in the example about checking whether the new, updated
    -- record looked any different than the old record before performing any operations.
    -- Ignoring that for now.
END IF;
END
$$
LANGUAGE plpgsql VOLATILE;

-- Bind function to trigger
CREATE TRIGGER trig_01_country_fact_ins_upd_del
INSTEAD OF INSERT OR UPDATE OR DELETE ON country_fact
FOR EACH ROW EXECUTE PROCEDURE trig_country_fact_ins_upd_del();

/* Try out some operations that rely on the trigger to do their job */

DELETE FROM country_fact WHERE fact = 'is east of France';

INSERT INTO country_fact(country_id, country_name, fact_id, fact) VALUES
    (4, 'Spain', 10, 'was home to the Moors'),
    (3, 'Italy', 11, 'has at least one river in it');

UPDATE country_fact SET fact = 'has Alps to the north' WHERE fact = 'is south of the Alps';

-- See what's in your examples
SELECT 'country' AS label;
SELECT * FROM country;
SELECT 'fact' AS label;
SELECT * FROM fact;
SELECT 'country_fact' AS label;
SELECT * FROM country_fact;

