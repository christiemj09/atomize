# Introduction

Decompose a database record into value tables and foreign keys.

# Challenges

* How best to construct the "fake" view that will be the staging area for record decomposition.
* Is there a simple way to specify the triggers to apply to a given insert? Some kind of config file?
* Is there a simple way to do a "select-sert"? Meaning always return primary key, but insert value if value doesn't exist.
* Scalable? Performance optimizations? Should *not* worry about this to start.
