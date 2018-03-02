-- Play around with using PL/Python triggers.

CREATE EXTENSION IF NOT EXISTS plpythonu;

DROP TABLE IF EXISTS python_trigger_data CASCADE;

CREATE TABLE python_trigger_data (
    a TEXT,
    b TEXT,
    c TEXT
);

DROP TABLE IF EXISTS python_trigger_log CASCADE;

CREATE TABLE python_trigger_log (
    message TEXT
);

-- Before inserting data, save messages about the data
CREATE OR REPLACE FUNCTION public.python_trigger()
RETURNS trigger
AS $$
    plan = plpy.prepare("INSERT INTO python_trigger_log(message) VALUES ($1)", ["text"])
    plpy.execute(plan, ['Type of TD["new"]: %s' % type(TD["new"]).__name__])
    plpy.execute(plan, ['Contents of TD["new"]: %s' % str(TD["new"])])
    plpy.execute(plan, ['Contents of TD["table_schema"]: %s' % TD["table_schema"]])
    plpy.execute(plan, ['Contents of TD["table_name"]: %s' % TD["table_name"]])
$$
LANGUAGE plpythonu;

-- Bind function to trigger
CREATE TRIGGER trig_01_python_trigger_data_ins
BEFORE INSERT ON python_trigger_data
FOR EACH ROW EXECUTE PROCEDURE python_trigger();

-- Insert an example record to try out the trigger
INSERT INTO python_trigger_data(a, b, c) VALUES
    ('one', 'two', 'three');

-- See what was logged
SELECT * FROM python_trigger_log;
