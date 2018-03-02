CREATE OR REPLACE FUNCTION public.atomize()
RETURNS INTEGER
AS $$
"""
Break up a record into application-defined pieces.
"""
# Useful documentation: https://www.postgresql.org/docs/9.6/static/plpython-trigger.html

# Important pieces of information:
# TD["new"]: The record to break apart.
# TD["table_schema"]: The schema of the relation being operated on.
# TD["table_name"]: The name of the relation being operated on.
$$
LANGUAGE plpythonu;
