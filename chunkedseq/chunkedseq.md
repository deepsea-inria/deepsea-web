% chunkedseq
% Theory and practice of chunked sequences
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

In this project, we address the question: 

> *Can we design asymptotically and practically efficient data structures
> for sequences that can support a broad range of operations, including
> push/pop operations on both ends, concatenation, and split at a
> specified position?*

In our ESA'14 paper [^1], we present two new algorithms for which we use
adaptations of the classic chunking technique for accelerating
tree-based representations of sequences by representing sequences as
trees of small, fixed-capacity arrays (i.e., chunks). We prove that
our algorithms deliver tight amortized, worst-case bounds with small
constant factors. We present two C++ implementations of our two
algorithms and a number of experiments comparing our implementations
to highly tuned and specialized sequence data structures, such as STL
deque and STL rope. This work presents the first data structures for
shared memory that simultaneously match the semantic and asymptotic
profile of the Finger Tree of Hinze and Patterson [^2], deliver strong
guarantees with respect to constant-factor performance (as well as
asymptotic performance), and compete well with highly tuned but more
specialized data structures.

We have made available a long version of our ESA'14 article which
includes appendices. In the appendix, there is additional discussion
of experiments, extra experimental results, and proofs.

- [Article](http://deepsea.inria.fr/chunkedseq/esa-2014-long.pdf) (long version)
- [Slides from talk](http://www.chargueraud.org/talks/2014_09_08_talk_esa_chunked.pdf)

Accessing and building the source code
======================================

Our C++ source code is supported by any platform on which the
following packages can be installed.

Package dependencies
--------------------

--------------------------------------------------------------
Package   Version      Details                                
-------   ----------   ---------------------------------------
gcc        >= 4.9.0    The chunkedseq code makes use of recent
                       features of C++1x, such as lambda
                       expressions.
                       [Source.](http://gcc.gnu.org/)

php        >= 5.3.10   PHP is called by the makefiles to track 
                       dependencies. This package is required 
                       only to use provided Makefiles.
                       [Source.](http://www.php.net/)

--------------------------------------------------------------

Download
--------

| Version       | Source package                                        | Documentation                                                    |
|---------------|-------------------------------------------------------|------------------------------------------------------------------|
| 1.0 (current) | [chunkedseq.tar.gz](packages/chunkedseq.tar.gz)       | [HTML](doc/html/index.html) [PDF](doc/latex/refman.pdf)          |

Running and extending our expriments
====================================

We encourage others to evaluate the findings of our empirical
study. To this end, we provide the source code of our benchmarks along
with the following instructions that show what steps a reviewer can
take to repeat our experiments and to interpret the data.

If you have trouble completing this process, please send email
describing the issue to [Mike Rainey](mailto:mike.rainey@inria.fr).

1. Prerequisites
----------------

To have enough room to run the experiments, your filesystem should
have about 80GB of free space and your machine at least 8GB or
RAM. These space requirements are so large because, for our
graph-search benchmarks, we use a few very large graphs. In addition
to those listed above, the following packages should be installed on
your test machine.

---------------------------------------------------------------------
Package   Version      Details                                
-------   ----------   ----------------------------------------------
ocaml     >= 4.00      This compiler is required to build our
                       benchmarking scripts. 
                       [Source.](http://www.ocaml.org/)

R         >= 2.4.1     This plotting package is required to
                       render plots.
                       [Source.](http://www.r-project.org/)

wget      (recent)     The benchmarking script invokes this 
                       script to download graph data.
                       [Source.](http://www.gnu.org/software/wget/)

latex     (recent)     Tables of results are generated in
                       and compiled by latex.
                       [Source.](http://www.latex-project.org/)

jemalloc  >= 3.6.0     Optionally used by our benchmarking
                       programs to improve performance. 
                       [Source.](http://www.canonware.com/jemalloc/)

---------------------------------------------------------------------

2. Getting the source code
--------------------------

You can either download our source files via [this
link](http://deepsea.inria.fr/chunkedseq/experiments/chunkedseq_bench.tar.gz) or,
if you prefer to use wget, you can skip to the next stage.

You can find relevant files in the following places:

---------------------------------------------------------------------
Locations                          Details
---------                          -----------------------------------
`chunkedseq/include/*.hpp`         implementation-specific files

`chunkedseq/bench/bench.cpp`       sequence-specific benchmarking 
`chunkedseq/bench/do_fifo.cpp`     codes

`graph/bench/search.cpp`           graph-search benchmarking codes
`graph/include/*.hpp`

`chunkedseq/stl/pushpop.cpp`       STL worst-case benchmark

---------------------------------------------------------------------

3. Running experiments
----------------------

To get started, first download our source file, unpackage, and build
our benchmarking script, namely `chunkedseq.byte`.

    $ wget http://deepsea.inria.fr/chunkedseq/experiments/chunkedseq_bench.tar.gz
    $ tar -xvzf chunkedseq_bench.tar.gz
    $ cd chunkedseq_bench/pbench
    $ make chunkedseq.byte

We need to do a little configuration before we can start running the
benchmarks. We found that we could get best results in our experiments
by using a custom implementation of malloc/free called
[jemalloc](http://www.canonware.com/jemalloc/). The custom allocator
is optional. If you do not want to use it, then simply run:

    $ ./chunkedseq.byte configure

Otherwise, run the following command, replacing `JEMALLOC_PATH` by the
path to the folder which contains the shared object files of jemalloc.

    $ ./chunkedseq.byte configure -allocator jemalloc \
            -path_to_jemalloc JEMALLOC_PATH

The following command starts the process. You may need to wait a few
hours for the process to complete.

    $ ./chunkedseq.byte paper

During the initialization phase, our script builds several binaries
and generates input data required by the graph-search experiments. The
input data may take about 30GB in total. Our script puts the input
data into the folder `_data`. After initialization completes, the
experiments run. During this time, be careful to ensure that the
machine is quiet (except for the currently running
experiment). Results from the experiments go into a new folder that is
created by the script. The name of this folder is reported by the
script after the script completes.

4. Interpreting results
-----------------------

When all of the experiments run to completion, results should be 
generated by the script and put into the following files.

---------------------------------------------------------------------
Locations                          Details
---------                          -----------------------------------
`tables_paper.tex`;                report of all experiments,
`tables_paper.pdf`                 showing runtimes in seconds

`tables_`*exp*`.tex`;              one table for each indidual
`tables_`*exp*`.pdf`               experiment *exp*

`_results/results_`*exp*`.txt`     raw input/output of each run for
                                   each individual experiment *exp*

`plots_chunk_size.pdf`             a scatter plot showing the results
                                   of the chunk-size experiment

---------------------------------------------------------------------

5. Advanced benchmarking
------------------------

Our benchmarking script supports a range of configurations that are
not discussed here. Refer to the following documentation for details:

- [PDF](experiments/chunkedseq.pdf) 
- [HTML](experiments/chunkedseq.html) 
- [Markdown](experiments/chunkedseq.md)

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

References
==========

Get the [bibtex file](chunkedseq.bib) used to generate these
references.

[^1]: [@chunkedseq14-esa]

[^2]: [@finger-trees]