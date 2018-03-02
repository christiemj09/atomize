#!/bin/bash

# Test atomize functionality, get to know views and triggers better.

# Make psql pretty :)
RUN="psql -U $(cred user) -d $(cred dbname) -h $(cred host) -f"

echo "RUN is:"
echo "$RUN"

echo

pause

echo "-*- Trying out modifiable views -*-"

$RUN tests/test_modifiable_view.sql

pause

echo "-*- Trying out triggers that handle data modifications -*-"

$RUN tests/test_modification_triggers.sql

pause

echo "-*- Trying out a beginner example of what atomize might look like -*-"

$RUN tests/test_baby_atomize.sql

pause

echo "-*- Trying out a function that returns a record set without explicitly stating its columns -*-"

$RUN tests/test_record_type.sql

pause

echo "-*- Seeing what variables inside a PL/Python trigger look like -*-"

$RUN tests/test_python_trigger.sql
