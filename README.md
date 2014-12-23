===========================
BiodataFinder
===========================

A gem for index biodata files and search through them
-------------------------------------------------------------

This gem allow you to index some biodata files (currently only gtf and tracking files) in an ElasticSearch index and then 
make some full text search over it. 

Overview
----------------

BiodataFinder have currently two interfaces: bdf-cli and bdf-si, the command line interface and the web one. 
At now it support gtf and tracking files.

Usage
------------------

Indexing
____________________

Via bdf-cli, indexing a file named 'somestuff.tracking'

``bdf-cli index somestuff.tracking``

If extension don't respect filetype's norm, you have to specify filetype with -t flag.

``bdf-cli index somestuff.bad_ext -t tracking``

If you want do indexing on a different index, you have to specify indexname vith -i flag.

``bdf-cli index somestuff.tracking -i new_index``

Searching
___________________

Via bdf-si. Start it vith: 

``bdf-si SINATRA_PORT_NUMBER ELASTICSEARCH_ADDRESS DEFAULT_INDEX INDEXES``

Go to the search page, fill the requested fields and push "search" ::

Via bdf-cli. 
Search 'tss7' on default index: 

``bdf-cli search tss7``

If you want do searching on a different index, you have to specify indexname vith -i flag. 

``bdf-cli search tss7 -i new_index``

Setting
_________________________

Set bdf-cli default index 

``bdf-cli set --def_index=NEW_DEF_INDEX``

Set bdf-cli indexes 

``bdf-cli set --indexes=INDEX1,INDEX2,INDEX3``

Watch bdf-cli indexes 

``bdf-cli ilist``





  
**Warning:** Keep in mind that this project is in a very alpha state and it's not ready for production systems.
