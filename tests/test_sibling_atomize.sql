-- An alternative trigger normalization mechanism that's hopefully lighter than the
-- FOR EACH ROW variant in test_baby_atomize.sql.

/* Tables to hold data and a view to insert data into */

DROP TABLE IF EXISTS a CASCADE;
CREATE TABLE a (
    id SERIAL PRIMARY KEY,
    text TEXT UNIQUE
);

DROP TABLE IF EXISTS a_staging CASCADE;
CREATE TABLE a_staging (
    a TEXT,
    inserted BOOLEAN DEFAULT FALSE
);

CREATE INDEX a_staging_inserted_idx
    ON a_staging(inserted);

CREATE OR REPLACE FUNCTION trig_ins_a_staging() RETURNS trigger AS
$$
BEGIN

    -- Insert new records into a
    INSERT INTO a(text)
    SELECT a
    FROM a_staging
    WHERE NOT inserted
    ON CONFLICT DO NOTHING;
    
    -- Mark new records as inserted
    UPDATE a_staging
    SET inserted = TRUE
    WHERE inserted = FALSE;
    
    RETURN NULL;
END;
$$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER trig_01_ins_a_staging
AFTER INSERT ON a_staging
FOR EACH STATEMENT EXECUTE PROCEDURE trig_ins_a_staging();

DROP TABLE IF EXISTS b CASCADE;
CREATE TABLE b (
    id SERIAL PRIMARY KEY,
    text TEXT UNIQUE
);

DROP TABLE IF EXISTS b_staging CASCADE;
CREATE TABLE b_staging (
    b TEXT,
    inserted BOOLEAN DEFAULT FALSE
);

CREATE INDEX b_staging_inserted_idx
    ON b_staging(inserted);

CREATE OR REPLACE FUNCTION trig_ins_b_staging() RETURNS trigger AS
$$
BEGIN

    -- Insert new records into b
    INSERT INTO b(text)
    SELECT b
    FROM b_staging
    WHERE NOT inserted
    ON CONFLICT DO NOTHING;
    
    -- Mark new records as inserted
    UPDATE b_staging
    SET inserted = TRUE
    WHERE inserted = FALSE;
    
    RETURN NULL;
END;
$$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER trig_01_ins_b_staging
AFTER INSERT ON b_staging
FOR EACH STATEMENT EXECUTE PROCEDURE trig_ins_b_staging();

DROP TABLE IF EXISTS a_b CASCADE;
CREATE TABLE a_b (
    a INTEGER REFERENCES a(id),
    b INTEGER REFERENCES b(id),
    UNIQUE(a, b)
);

DROP TABLE IF EXISTS a_b_staging CASCADE;
CREATE TABLE a_b_staging (
    a TEXT,
    b TEXT,
    inserted BOOLEAN DEFAULT FALSE
);

CREATE INDEX a_b_staging_inserted_idx
    ON a_b_staging(inserted);

/* A trigger function to break apart and store inserted values */

CREATE OR REPLACE FUNCTION trig_ins_a_b_staging() RETURNS trigger AS
$$
BEGIN
    
    -- Insert new records into a
    INSERT INTO a_staging(a)
    SELECT a FROM a_b_staging;
    
    -- Insert new records into b
    INSERT INTO b_staging(b)
    SELECT b FROM a_b_staging;
    
    -- Insert new records into a_b
    INSERT INTO a_b(a, b)
    SELECT a.id AS a_id, b.id AS b_id
    FROM a, b, a_b_staging
    WHERE a.text = a_b_staging.a
      AND b.text = a_b_staging.b
    ON CONFLICT DO NOTHING;
    
    -- Mark new records as inserted
    UPDATE a_b_staging
    SET inserted = TRUE
    WHERE inserted = FALSE;
    
    RETURN NULL;
END;
$$
LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER trig_01_ins_a_b_staging
AFTER INSERT ON a_b_staging
FOR EACH STATEMENT EXECUTE PROCEDURE trig_ins_a_b_staging();

/* Try doing some inserting, see if it handles it correctly */

INSERT INTO a_b_staging(a, b) VALUES
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
SELECT 'a_staging' AS label;
SELECT * FROM a_staging;
SELECT 'b_staging' AS label;
SELECT * FROM b_staging;
SELECT 'a_b_staging' AS label;
SELECT * FROM a_b_staging;
