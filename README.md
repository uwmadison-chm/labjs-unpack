# Lab.js data utilities

* `unpack-labjs-from-sqlite.R`: Turn a SQLite into a TSV, based originally on the 
  utilities script from the Lab.js repo
* `unpack-labjs-from-sqlite.py`: Like above, for Python so there's less R 
  dependencies, but not finished (TODO)
* `unpack-labjs-from-qualtrics.py`: Unpack Qualtrics JSON lump


## TODO

* Make `unpack-labjs-from-qualtrics.py` unpack the sub-column `meta` which has a 
  bunch of JSON-encoded metadata in the first row of each run's data
