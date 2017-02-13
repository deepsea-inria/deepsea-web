% pdfs
% Fast Parallel Graph-Search with Splittable and Catenable Frontiers
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

This project concerns parallel graph traversal (or, graph search) over
directed, in-memory graphs using shared-memory, multiprocessor
machines (aka multicore). In this project, we address the question:

> *Can we design asymptotically and practically algorithms for the
> efficient traversal of in-memory directed graphs? Furthermore, can
> we design such algorithms so that, for any input graph, the cost of
> load balancing is negligible, yet the amount of parallelism being
> utilized is close to the hard limit imposed by the input graph and
> the machine?*

Such algorithms are desireable because multicore hardware demands
computations that make the most economical use of their time. In
contrast, algorithms that spend many cycles performing load-balancing
work are often slower and may consume excess power. There are two
competing forces that make this problem challenging. First, the space
of possible input graphs is huge, and the graphs vary substantially in
their structure. Particularly challenging inputs include long chains
and, more generally, high diameter graphs. To add to the challenge,
graph traversal algorithms typically discover new regions of graph on
the fly. So, the second competing force is the fact that new
parallelism is discovered online, thus challenging the load-balancing
algorithm to adapt quickly.

To summarize, a good graph-traversal algorithm must cope with the
large input space, rapid-fire parallelism, yet keep load-balancing
overheads low. There are several algorithms proposed to this end. All
of these algorithms and related issues are covered in detail in our
paper. Overall, we found that, although the previous state of the art
performs well for certain classes of graphs, none meet the main
challenge *for all graphs*.

In our Supercomputing'15 paper[^1], we answer the main question from
above in the affirmative: we present a new algorithm that performs a
DFS-like traversal over a given graph. We prove that the algorithm is
*strongly work efficient*, meaning that, in addition to having the
linear upper bound on the total work performed, the algorithm
effectively amortizes overheads, such as the cycles spent balancing
traversal workload between cores. Put a different way, we prove that,
for any input, the algorithm confines the amount of load-balancing
work to a small fraction of the total (linear) running time. Then, we
prove that the algorithm achieves a high degree of parallelism, that
is, near optimal under the constraints of the graph. Finally, we
present an experimental evaluation showing that, thanks to reducing
overheads and increasing parallelism, our implementation of the
algorithm outperforms two other state-of-the-art algorithms in all but
a few cases, and in some cases, far outperforms the competition.

We made available a long version of our Supercomputing'15 article
which includes appendices. In the appendix, there is a longer version
of one of the proofs

- [Article](http://chargueraud.org/research/2015/pdfs/pdfs_sc15.pdf)
- [Slides from talk](http://gallium.inria.fr/~rainey/slides/sc15-pdfs-talk.pdf)
- [Video copy of talk](https://www.youtube.com/watch?v=kOausvmMtmM)

Run our experimental evaluation
===============================

The source code we used for our experimental evaluation is hosted by a
[Github
repository](https://github.com/deepsea-inria/pasl/tree/new-sc15-graph/).

1. Prerequisites
----------------

To have enough room to run the experiments, your filesystem should
have about 300GB of free hard-drive space and your machine at least
128GB or RAM. These space requirements are so large because some of
the input graphs we use are huge.

The following packages should be installed on your test machine.

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

[ipfs](https://ipfs.io/)                            recent        We are going to use this software to
                                                                  download data sets for our experiments.
----------------------------------------------------------------------------------------------------------

Table: Software dependencies for our PASL benchmarks.

2. IPFS
-------

IPFS is a tool that is useful for transfering large amounts of data
over the internet. We need this tool because our experiments use large
input graphs. After installing the package, we need to initialize the
local IPFS configuration.

~~~~
$ ipfs init
~~~~

Then, we need to run the IPFS daemon. This process needs to be running
until after all input graphs have been successfully downloaded to your
machine.

~~~~
$ ipfs daemon &
~~~~

TODO: write instructions so that i can renew the quickcheck/graph files in ipfs

3. Getting the sources
----------------------

Now, create a new directory in which to store all of our the code and
data.

~~~~
$ mkdir sc15
$ cd sc15
~~~~

To start downloading, first get the [downloader
script](get.sh).

~~~~
$ wget http://deepsea.inria.fr/graph/get.sh
$ chmod u+x get.sh
$ ./get.sh
~~~~

4. Building the binaries
------------------------

5. Running the experiment
-------------------------

6. Analyzing the results
------------------------

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

References
==========

Get the [bibtex file](graph.bib) used to generate these
references.

[^1]: [@PDFS_15]
