-- Make a function that returns records.

DROP TABLE IF EXISTS arbitrary_records;

CREATE TABLE arbitrary_records (
    a TEXT,
    b TEXT,
    c TEXT
);

INSERT INTO arbitrary_records(a, b, c) VALUES
    ('one', 'two', 'three'),
    ('four', 'five', 'six');

-- Well, not EXACTLY what you were going for since you have to specify a specific table,
-- but it's a little progress.
CREATE OR REPLACE FUNCTION public.get_arbitrary_records() RETURNS SETOF arbitrary_records
AS $$
BEGIN
    RETURN QUERY SELECT * FROM arbitrary_records;
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM get_arbitrary_records();
