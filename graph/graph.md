% pasl graph project
% Fast Parallel Graph-Search with Splittable and Catenable Frontiers
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

Run our experimental evaluation
===============================

Software dependencies
---------------------

----------------------------------------------------------------------------------------------------------
Package                                            Version        Details
------------------------------------------------   ----------     ----------------------------------------
[gcc](https://gcc.gnu.org/)                         >= 4.9.0      Recent gcc is required because PASL 
                                                                  makes heavy use of features of C++1x,
                                                                  such as lambda expressions and
                                                                  higher-order templates.

[php](http://www.php.net/)                          >= 5.3.10     PHP is currently used by the build system 
                                                                  of PASL. 

[ocaml](http://www.ocaml.org/)                      >= 4.00       Ocaml is required to build the
                                                                  benchmarking script.

[R](http://www.r-project.org/)                      >= 2.4.1      The R tools is used by our scripts to
                                                                  generate plots.
                                               
[tcmalloc](http://goog-perftools.sourceforge.net)   2.2.1         This package provides scalable heap
                                                                  allocation that is crucial for all of 
                                                                  the graph-search algorithms.

[hwloc](http://www.open-mpi.org/projects/hwloc/)    recent        PASL uses this package to force
                                                                  interleaved NUMA allocation; as
                                                                  such this package is optional and only
                                                                  really relevant for NUMA machines.

----------------------------------------------------------------------------------------------------------

Table: Software dependencies for our PASL benchmarks.

Getting the sources
-------------------

Building the binaries
---------------------

### Building Ligra

### Building LS PBFS

Running the experiment
----------------------

Analyzing the results
---------------------

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

References
==========

Get the [bibtex file](graph.bib) used to generate these references.
