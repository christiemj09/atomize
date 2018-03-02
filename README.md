# Introduction

Decompose a database record into value tables and foreign keys.

# Challenges

1. How best to construct the "fake" view that will be the staging area for record decomposition.
2. Is there a simple way to specify the triggers to apply to a given insert? Some kind of config file?
3. Is there a simple way to do a "select-sert"? Meaning always return primary key, but insert value if value doesn't exist.
4. Scalable? Performance optimizations? Should *not* worry about this to start.

# (Partial) Answers

* Addressing 1: See `tests/test_modifiable_view.sql`, `tests/test_modification_triggers.sql`
* Addressing 3: See `tests/test_baby_atomize.sql`

# Thoughts/Planning

* Each table to be decomposed should have a corresponding insertion view.
* Each insertion view should have spec that formally describes how to decompose it.
  These specs should probably be JSON: Easy to produce, easy to read, easy to code against.
* JSON can be looked up and interpreted by trigger functions. Ideally, there should be a
  *single* trigger function that generates dynamic SQL according to a JSON spec and executes it.
* There should be a table that maps views (by their schema and name?) to handling instructions
  (JSON specs). Absence of a relation's name in this table implies that the relation is a
  table, and that there's no more decomposition to be performed.
* Probably need to study triggers more to make sure you're not missing anything key that
  would make this a better project.
