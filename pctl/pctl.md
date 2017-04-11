% pctl
% The Parallel Container Template Library
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

Source code and documentation
=============================

Our source code is hosted on a [Github
repository](https://github.com/deepsea-inria/pctl).

Documentation is available in [HTML](doc/pctl.html) or
[PDF](doc/pctl.pdf) format.

Run our experimental evaluation
===============================

1. Prerequisites
----------------

To have enough room to run the experiments, your filesystem should
have about 300GB of free hard-drive space and your machine at least
128GB or RAM. These space requirements are so large because some of
the inputs are huge.

The following packages should be installed on your test machine.

-----------------------------------------------------------------------------------
Package    Version        Details
--------   ----------     ---------------------------------------------------------
gcc         >= 4.9.0      Recent gcc is required because pdfs 
                          makes heavy use of features of C++1x,
                          such as lambda expressions and
                          higher-order templates.
                          ([Home page](https://gcc.gnu.org/))

php         >= 5.3.10     PHP is currently used by the build system 
                          of pdfs.
                          ([Home page](http://www.php.net/))

ocaml        >= 4.00       Ocaml is required to build the
                           benchmarking script.
                           ([Home page](http://www.ocaml.org/))

R            >= 2.4.1      The R tools is used by our scripts to
                           generate plots.
                           ([Home page](http://www.r-project.org/))
                                               
hwloc        recent        This package is used by pdfs to force
                           interleaved NUMA allocation; as
                           such this package is optional and only
                           really relevant for NUMA machines.
                           ([Home page](http://www.open-mpi.org/projects/hwloc/))

tcmalloc     recent        This package provides a drop-in
                           replacement for system malloc.
                           ([Home page](http://goog-perftools.sourceforge.net/))

ipfs         recent        We are going to use this software to
                           download data sets for our experiments.
                           ([Home page](https://ipfs.io/))

openssl      recent        This library is required by the hash
                           benchmark.

pkgconfig    recent        This package is used by the makefile
                           to locate paths to packages, such
			   as hwloc
-----------------------------------------------------------------------------------

Table: Software dependencies for our pdfs benchmarks.

2. Getting experimental data
----------------------------

IPFS is a tool that is useful for transfering large amounts of data
over the internet. We need this tool because our experiments use large
input graphs. After installing the package, we need to initialize the
local IPFS configuration.

~~~~
$ ipfs init
~~~~

***Warning: disk space.*** The default behavior of IPFS is to keep a
cache of all downloaded files in the folder `~/.ipfs/`. Because the
graph data is several gigabytes, the cache folder should have at least
twice this much free space. To select a different cache folder for
IPFS, before issuing the command `ipfs init`, set the environment
variable `$IPFS_PATH` to point to the desired path.

Next, we need to run the IPFS daemon. This process needs to be running
until after all input graphs have been successfully downloaded to your
machine.

~~~~
$ ipfs daemon &
~~~~

~~~~
ipfs get QmauU3YTG7D7Kq729pVRX4noVwmaDwDzVnJcd5VYvUCk31 -o _data
~~~~

3. Setting paths

`pbbs-pctl/bench/settings.sh`

~~~~
LIB_OPENSSL_PATH=/usr/lib/x86_64-linux-gnu/
~~~~

~~~~
USE_ALLOCATOR=tcmalloc
TCMALLOC_PATH=/home/mrainey/Installs/gperftools/lib/
~~~~

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- Vitaly Aksenov
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

References
==========

Get the [bibtex file](pctl.bib) used to generate these
references.
