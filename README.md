# download_geba
Perl script to download the 1003 GEBA genomes [doi:10.1038/nbt.3886](http://www.nature.com/nbt/journal/vaop/ncurrent/full/nbt.3886.html)

WARNING - this is hacked together Perl that has been tested precisely once.  There is little checking/testing involved.  Use at own risk.

Find a directory you have write access to then:  

```sh
perl download.pl
```

I also added auto-magically generated taxonomic info in file taxinfo.txt.  Columns are:

* GEBA ID
* GEBA name
* NCBI taxonomy ID
* Taxonomic tree
