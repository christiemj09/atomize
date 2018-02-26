-- Example views and triggers.

DROP TABLE IF EXISTS input_table CASCADE;

CREATE TABLE input_table (
    id INTEGER PRIMARY KEY,
    a TEXT,
    b INTEGER
);

INSERT INTO input_table(id, a, b) VALUES
    (1, 'Athabasca', 2),
    (2, 'Bermuda', 5),
    (3, 'Damascus', 10),
    (4, 'Eritrea', -1);

CREATE OR REPLACE VIEW output_view AS
    SELECT id, a, b
    FROM input_table
    WHERE b > 0;

-- See what's in your examples
SELECT 'input_table' AS label;
SELECT * FROM input_table;
SELECT 'output_view' AS label;
SELECT * FROM output_view;

/* Perform some operations on data */

-- This should delete records from input_table
DELETE FROM output_view
WHERE a = 'Bermuda';

-- This should leave the corresponding record in input_table alone
UPDATE output_view SET a = 'France' WHERE a = 'Eritrea' AND b = -1;

-- This should hide a record from input_table from output_view
UPDATE output_view SET b = -2 WHERE b = 10;

-- See what's in your examples
SELECT 'input_table' AS label;
SELECT * FROM input_table;
SELECT 'output_view' AS label;
SELECT * FROM output_view;

-- Add WITH CHECK OPTION to view to prevent inserts or updates outside the view
CREATE OR REPLACE VIEW output_view AS
    SELECT id, a, b
    FROM input_table
    WHERE b > 0 WITH CHECK OPTION;

-- Set data back to original values
UPDATE input_table SET b = 10 WHERE a = 'Damascus';

-- This should now throw an error
UPDATE output_view SET b = -2 WHERE b = 10;

