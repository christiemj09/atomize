-- See if you can write a trigger that decomposes a record according to JSON instructions
-- stored in the database.

/* Use the same data setup as test_baby_atomize.sql */

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

/* Data add-ons */

DROP TABLE IF EXISTS test_atomize CASCADE;
CREATE TABLE test_atomize (
    id SERIAL PRIMARY KEY,
    table_schema TEXT,
    table_name TEXT,
    instructions JSONB,
    UNIQUE(table_schema, table_name)
);

/* Define and bind trigger */

/* Format of instructions
{
    "inserts": [
        {
            "table_schema": "",
            "table_name": "",
            "send_values_to": {},
            "get_id": "",
            "send_id_to": ""
        }
    ],
    "atomized_schema": "",
    "atomized_table": ""
}
*/

CREATE OR REPLACE FUNCTION public.get_instructions(table_schema TEXT, table_name TEXT)
RETURNS TEXT
AS $$

# Fetch instructions for how to handle this record
get_instructions = plpy.prepare("""
SELECT instructions
FROM test_atomize
WHERE table_schema = $1
AND table_name = $2
""", ["text", "text"])
result, = plpy.execute(get_instructions, [table_schema, table_name])
return str(result.keys())

$$
LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION public.trig_test_atomize()
RETURNS trigger
AS $$

# Store ids of value records
atomized = {}

# Fetch instructions for how to handle this record
get_instructions = plpy.prepare("""
SELECT instructions
FROM test_atomize
WHERE table_schema = $1
AND table_name = $2
""", ["text", "text"])
result, = plpy.execute(get_instructions, [TD["table_schema"], TD["table_name"]])

# Follow instructions
for recipe in result['instructions']['inserts']:
    
    # Build dynamic query to get record id
    get_id = """
    SELECT {get_id} FROM {table_schema}.{table_name} WHERE {where_clause};
    """
    conditions = [
        ' = '.join([plpy.quote_ident(to_attr), plpy.quote_literal(TD['new'][from_attr])])
        for attr, val in recipe['send_values_to']
    ]
    where_clause = ' AND '.join(conditions)
    
    # Get record id if record exists
    rv = plpy.execute(get_id.format(
        get_id=plpy.quote_ident(recipe['get_id']),
        table_schema=plpy.quote_ident(recipe['table_schema']),
        table_name=plpy.quote_ident(recipe['table_name']),
        where_clause=where_clause
    ))
    records = list(rv)
    
    # Otherwise, insert first
    if records == []:
        
        # Build dynamic query to insert new record, get id
        insert_get_id = """
        INSERT INTO {table_schema}.{table_name}({attr_list}) VALUES ({val_list}) RETURNING {get_id};
        """
        attrs, vals = zip(*[
            [plpy.quote_ident(to_attr), plpy.quote_literal(TD['new'][from_attr])]
            for to_attr, from_attr in recipe['send_values_to'].items()
        ])
        attr_list, val_list = map(lambda seq: ', '.join(seq), [attrs, vals])
        
        # Get record id from insert
        rv = plpy.execute(insert_get_id.format(
            table_schema=plpy.quote_ident(recipe['table_schema']),
            table_name=plpy.quote_ident(recipe['table_name']),
            attr_list=attr_list,
            val_list=val_list,
            get_id=plpy.quote_ident(recipe['get_id'])
        ))
        record, = rv
    else:
        record, = records
    
    # Populate atomized record
    atomized[recipe['send_id_to']] = record[recipe['get_id']]

# Build dynamic query to insert into atomized table
insert_atomized = """
INSERT INTO {atomized_schema}.{atomized_table}({attr_list}) VALUES ({val_list});
"""
attrs, vals = zip(*[
    [plpy.quote_ident(attr), plpy.quote_literal(val)]
    for attr, val in atomized.items()
])
attr_list, val_list = map(lambda seq: ', '.join(seq), [attrs, vals])

# Insert into atomized table
plpy.execute(insert_atomized.format(
    atomized_schema=plpy.quote_ident(result['instructions']['atomized_schema']),
    atomized_table=plpy.quote_ident(result['instructions']['atomized_table']),
    attr_list=attr_list,
    val_list = val_list
))
            
$$
LANGUAGE plpythonu;

-- Bind function to trigger
CREATE TRIGGER trig_01_insert_a_b
INSTEAD OF INSERT ON insert_a_b
FOR EACH ROW EXECUTE PROCEDURE trig_test_atomize();

-- Insert some instructions
INSERT INTO test_atomize(table_schema, table_name, instructions) VALUES
    ('public', 'insert_a_b', $$
        {
            "inserts": [
                {
                    "table_schema": "public",
                    "table_name": "a",
                    "send_values_to": {"a": "text"},
                    "get_id": "id",
                    "send_id_to": "a"
                },
                {
                    "table_schema": "public",
                    "table_name": "b",
                    "send_values_to": {"b": "text"},
                    "get_id": "id",
                    "send_id_to": "b"
                }
            ],
            "atomized_schema": "public",
            "atomized_table": "a_b"
        }
    $$);

/* Try doing some inserting, see what happens :) */

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
SELECT 'instructions' AS label;
SELECT get_instructions('public', 'insert_a_b');

-- Hooh. Finished but not yet tested.






