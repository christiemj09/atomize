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
