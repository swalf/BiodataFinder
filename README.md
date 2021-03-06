===========================
Biodatafinder
===========================

A gem for index biodata files and search through them
-------------------------------------------------------------

This gem allow you to index some biodata files (currently only gtf and tracking files) in an ElasticSearch index and then
make some full text search over it.

Overview
----------------

Biodatafinder have currently two interfaces: bdf-cli and bdf-si, the command line interface and the web one.
At now it support gtf and tracking files.

Softare requirement
----------------------

  - Ruby ~> 2.0
  - ElasticSearch >= 1.3
  - JSON ~> 1.8
  - Thor ~> 0.18
  - Sass ~> 3.4
  - Progressbar ~> 0.9
  - Sinatra ~> 1.4

Initial configuration
-------------------------

  - Install biodatafinder gem.
  - Start an ElasticSearch server (You can do this with 'your-elasticsearch-path/bin/elasticsearch').
  - Run initial command line setup via (--interactive option) for interactive setup or manually set the required fields:
    - The address where Biodatafinder will search Elasticsearch instance (--es_address option).
    - The index (BDF database on Elasticsearch) where you want do indexing, if you don't have any previus data fill it by a meaningfull name (--bdf_index option).
    - If the index specificated is new or you want to load a pre-existent data (--idx_exists flag).
    - The maximum number of results that BDF will return (--max_results option).

Usage
------------------

Indexing
____________________

Via bdf-cli, indexing a file named 'somestuff.tracking'

``bdf-cli index somestuff.tracking``

If extension don't respect filetype's norm, you have to specify filetype with -t flag.

``bdf-cli index somestuff.bad_ext -t tracking``

If you want index more than a file at time, you must use -b flag with the list of files. File must be of the same filetype.

``bdf-cli index -b foo.tracking bar.tracking baz.tracking qux.tracking ...``

Searching
___________________

**Via bdf-cli**.
Search 'tss7':

``bdf-cli search tss7``

Search function is case-insensitive.
If you want search only by part of word, use wildcards '*' (placeholder for zero or more unknown characters) and '?' (placeholder for exactly one unknown character.

``bdf-cli search en?g000001*``

If you want search only in file with specificated filetype use flag -t follewed by filetype:

``bdf-cli search ENST00000476201 -t tracking``

If you want search only in a list of directories specificated use flag -d follewed by list of directories:

``bdf-cli search ENST00000476201 -d "data/foo" "data/bar" "data/baz" "data/qux"``

If you want search only in a list of files specificated use flag -f follewed by list of files:

``bdf-cli search ENST00000476201 -f "data/foo/file1.gtf" "data/foo/file2.gtf" "data/foo/file3.gtf"``

If you want

**Via bdf-si.**
In order to use bdf-si you have to write a little JSON file like this:

    {
       "max_results": MAX_NUMBER_OF_RESULTS,
       "bdf_index": "INDEX_NAME",
       "es_address": "ES_ADDRESS",
       "si_port": PORT_WHERE_WEB_INTERFACE_WILL_STARTS
    }

And save it to ``~/.biodatafinder/bdf-si.conf``

Go to the search page, fill the requested fields and push "search" ::

Management
_________________________

Set bdf index:

``bdf-cli set --index=NEW_INDEX [--idx_exists]``

Watch list of file indexed by Biodatafinder:

``bdf-cli filelist``

Delete a file from BDF database (copy on disk will be leaved untouched):

``bdf-cli delete -f filepath``

Delete a full bdf-cli index

``bdf-cli delete -i INDEX_NAME``


RoadMap
----------------

  - [4] Provide an interface for R, Python, Ruby, Perl.
  - [3] Create a ncurses interface for command line
  - [2] Create a pretty table for the command line.
  - [1] Support search by coordinates using tabix where possible.


ChangeLog
----------------

0.5.0
____________________

  - Introducing search by coordinates for some filetype (fpkm_trackin). Coordinates are store into ElasticSearch, see RoadMap [1] for further details.
  - Move to stable beta, remove pre

0.4.0.pre
____________________

  - Search combines multiple terms at onces
  - Dockerfile is working properly

0.3.9
____________________

  - Public release







**Warning:** Keep in mind that this project is in alpha state. Carefully deem its results.
