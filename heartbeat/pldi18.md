% Heartbeat Scheduling: Provable Efficiency for Nested Parallelism
% Umut Acar; Arthur Charguéraud; Adrien Guatto; Mike Rainey; Filip Sieczkowski
% Project page

Overview
========

A classic challenge in parallel computing is to take a parallel
program that is written in a high-level style, for example, in
nested-parallel style with fork-join constructs, and have an optimzied
version of the program run efficiently on a real machine. Even today,
to obtain such an optimized version one must deal with the problem of
*granularity control*. The reason this problem exists relates to the
fact that in every parallel system there is a cost to pay to realize
any opportunity for parallelism that exists in the application. Have
the program realize too much of the available parallelism, and the
program will be slowed by threading overheads. But have the program
realize too little and the program will underutilize the available
processors. The fundamental challenge is, therefore, to find a
technique that can consistently strike a balance between the two
extremes.

Although it might be considered solved in theory, the
granularity-control problem is not solved in practice, because in
existing parallel systems the overheads of creating and managing
parallel threads can easily overwhelm their benefits. Programmers
compensate for such inefficiencies by tuning their code, i.e., by
performing manual granularity control. Such manual tuning is
problematic, unfortunately, because the tuning itself consumes
precious developer time and the tuning methods typically consist of
heuristics, such as manually specified threshold settings, that
deliver highly variable results, sometimes with extremely poor
performance, and often do not automatically port well to different
hardware and software environments [@LAZY_SCHEDULING_14].

In this work, we propose a new approach to the granularity-control
problem. The idea is that, as usual, the program runs multiple of its
own threads of execution on a number of processors. Each such thread
executes in a mostly sequential fashion, operating on its own private
call stack, by pushing and popping frames from its stack using the
usual stack discipline. On a regular basis, each processor checks a
local timer to see how long it has been since the previous time the
processor generated a new parallel thread. The purpose of the timer is
to ensure that a new thread is created by the scheduler only if there
has been sufficient time since the previous thread creation to pay for
the cost of next thread creation. We call the interval at which a
processor generates new parallel threads its *heartbeat*. When it
performs a heartbeat, the processor looks in its own call stack to see
if there exists a latent parallel branching point. If it does exist,
then the call stack is updated by the scheduler so that the latent
parallelism can safely migrate to scheduling queues, and from there to
different processors via load balancing.

To evaluate this idea, we performed two studies. The first one encodes
the Heartbeat algorithm as a formal semantics and uses the semantics
to prove key bounds on the performance of the algorithm. The first
bound shows that, for any program, the Heartbeat algorithm can, thanks
to its use of amortization, confine the thread-related overheads to a
desired fraction, for example, to under 1% of total running time. The
second bound establishes that the scheduler can reduce parallelism by
no more than a small constant factor, thereby confirming that the
proposed algorithm achieves the goal of consistently striking a
balance between under and over parallelization. We formalized this
theory in the Coq proof assistant.

The second study considers a prototype implementation of the Heartbeat
algorithm. This implementation, the experiments, and the formal proof,
are detailed in the copy of our paper linked below.

- Authors' copy of the paper [@HEARTBEAT_18]

This web page provides supplemental materials for the paper. In what
follows, we provide documentation for the Coq proof that appears in
the paper. We then provide links and documentation to the prototype
system, and finally we give detailed instructions for how interested
parties can repeat the experimental study.

Formal bounds and the Coq proof
===============================

TODO: Adrien, please put the documentation here.

Source code for the prototype
=============================

The source code we used to evaluate our Heartbeat Scheduler is
available as a [Github
repository](https://github.com/deepsea-inria/encore). Here, we
document a few key parts of the code base.

AST example
-----------

For reasons described in the paper, the prototype involves a custom
AST representation of the benchmarks. The representation requires that
each function (involving any parallelism) be encoded as a C++
class. To see comparison between the AST representation and the
various others, the prototype code base provides a number of example
variants of the Fibonacci function.

- [fib.cpp](https://github.com/deepsea-inria/encore/blob/master/example/fib.cpp)

In this file, the `fib` function corresponds to the purely sequential
version. The `fib_cilk` function represents the Cilk Plus version. The
`fib_manual` class represents the manual encoding, whereby the
Fibonacci function is represented by instances of the built-in
lightweight thread class. The `fib_cfg` class represents the
control-flow graph encoding of the fib function. Although this
representation is used only inside of the prototype scheduler, it is
nevertheless useful to understand because this version is actually the
versions that the scheduler uses. Finally, there is the `fib_dc`
class. This version is the one we used to encode the benchmarks. This
version is a thin layer over the control-flow graph: the prototype
automatically compiles from `fib_dc` to a control-flow version which
is essentially the same as `fib_cfg`.

The interpreter
---------------

The [interpreter
module](https://github.com/deepsea-inria/encore/blob/master/include/interpreter.hpp)
implements the core of the prototype. The `step` function implements
the sequential state transition rule, and the `promote` function the
promotion rules.

The benchmark codes
-------------------

We put the encodings of the benchmarks in [the `bench`
folder](https://github.com/deepsea-inria/encore/tree/master/bench).

The cactus stack
----------------

We implemented this data structure as an [independent
library](https://github.com/deepsea-inria/cactus-stack). The prototype
uses the version of cactus stack implemented in
`include/cactus-plus.hpp`.

The modified Cilk Plus runtime
------------------------------

We used Cilk Plus as the baseline for our benchmarks. To obtain key
statistics, we extended the Cilk Plus runtime to report number of Cilk
threads spawned and total idle time. Fortunately, these statistics are
easy to collect without affecting performance noticeably. We have
created a Git repository to share our [modified version of the Cilk
Plus
runtime](https://github.com/deepsea-inria/cilk-plus-rts-with-stats).

How to repeat the experimental evaluation
=========================================

We encourage other interested parties to repeat our empirical
study. The instructions in this document show how

- to obtain the required software dependencies,
- to obtain the input data needed to run the experiments,
- to configure the scripts that run the experiments, 
- to run the experiments, and
- to interpret the results of the experiments.

If you encounter difficulties while using this guide, please email
[Mike Rainey](mailto:me@mike-rainey.site).

Prerequisites
-------------

To have enough room to run the experiments, your filesystem should
have about 300GB of free hard-drive space and your machine at least
128GB or RAM. These space requirements are so large because some of
the input graphs we use are huge.

The following packages should be installed on your test machine.

-----------------------------------------------------------------------------------
Package    Version         Details
--------   ----------      --------------------------------------------------------
gcc         >= 6.1         Recent gcc is required because pdfs 
                           makes heavy use of features of C++1x,
                           such as lambda expressions and
                           higher-order templates.
                           ([Home page](https://gcc.gnu.org/))

ocaml        >= 4.02       Ocaml is required to build the
                           benchmarking script.
                           ([Home page](http://www.ocaml.org/))

R            >= 2.4.1      The R tools is used by our scripts to
                           generate plots.
                           ([Home page](http://www.r-project.org/))
                                               
tcmalloc     recent        *Optional dependency* (See instructions below).
                           This package is used to provide a scalable
                           heap allocator 
                           ([Home page](http://goog-perftools.sourceforge.net/doc/tcmalloc.html))

hwloc        recent        *Optional dependency* (See instructions 
                           below). This package is used to force
                           interleaved NUMA allocation; as
                           such this package is optional and only
                           really relevant for NUMA machines.
                           ([Home page](http://www.open-mpi.org/projects/hwloc/))

ipfs         recent        We are going to use this software to
                           download data sets for our experiments.
                           ([Home page](https://ipfs.io/))
-----------------------------------------------------------------------------------

Table: Software dependencies for the benchmarks.

Now that all the prerequisites are installed on the test machine, we
can proceed to download the source files we need to build the
benchmarks. First, download

- [the downloader script](https://raw.githubusercontent.com/deepsea-inria/encore/master/script/download-sources.sh)

and let `$DOWNLOADS` denote the path to the place where the
`download-sources.sh` script is stored. Now, create a new directory,
say, `heartbeat-pldi18` in which to put the source files and, from
that directory, run the download script.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ cd heartbeat-pldi18
$ $DOWNLOADS/download-sources.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Even though the required version of GCC comes packaged with full
support for Cilk Plus, there are some additional features that we
needed from Cilk that are not provided in GCC. In particular, our
experiments need a Cilk Plus runtime that emits statistics, such as
number of threads spawned and overall processor utilization. To that
end, we have implemented our own custom version of the Cilk Plus
runtime and provided a script to build our custom Cilk Plus
runtime.

So, get the build process started, from the same directory, download

- [the custom Cilk Plus runtime installer script](https://raw.githubusercontent.com/deepsea-inria/encore/master/script/build-cilk-plus-rts.sh)

and then run the script, ensuring the build process completes
successfully.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ $DOWNLOADS/build-cilk-plus-rts.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Getting the input data
----------------------

We use IPFS as the tool to disseminate our input data files. After
installing IPFS, we need to initialize the local IPFS configuration.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ ipfs init
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::::: {#warning-disk-space .warning}

**Warning:** disk space. The default behavior of IPFS is to keep a
cache of all downloaded files in the folder `~/.ipfs/`. Because the
graph data is several gigabytes, the cache folder should have at least
twice this much free space. To select a different cache folder for
IPFS, before issuing the command ipfs init, set the environment
variable `$IPFS_PATH` to point to the desired path.

:::::

In order to use IPFS to download files, the IPFS daemon needs to be
running. You can start the IPFS daemon in the following way, or you
can start it in the background, like a system service. Make sure that
this daemon continues to run in the background until after all of the
input data files you want are downloaded on your test machine.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ ipfs daemon
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

How to build the benchmarks
---------------------------

Our benchmarking script is configured to automatically download the
input data as needed. We can get started by changing to the
benchmarking directory and building the script.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ cd encore/bench
$ make bench.pbench
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::::: {#optional-heap-allocator .optional}

**Optional:** Using a custom heap allocator

We found in our experiments that the heap allocators (i.e., the
underlying implementation of `malloc` and `free`) packaged with
various Linux distributions sometimes do not scale well. If this
situation applies to your test machine, then the comparisons being
made in our benchmarks may be compromised by the fact that benchmarks
that are the native, Cilk Plus codes use the custom, scalable heap
allocator provided by Cilk Plus, whereas the benchmarks that are
native, encore codes use the potentially slow, default system
allocator.

For this reason, especially if results are obviously biased against
encore, we recommend running all of the experiments using the same
heap allocator. In our experiments, we used Google's custom heap
allocator, namely
[tcmalloc](http://goog-perftools.sourceforge.net/doc/tcmalloc.html). In general,
you can build with any drop-in replacement for `malloc`/`free` by
configuring the benchmark settings appropriately.

To use tcmalloc, for example, we need to insert into the file
`encore/bench/settings.sh` a line like the following.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CUSTOM_MALLOC_PREFIX=-ltcmalloc
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is fine to add to the "custom, malloc prefix" additional arguments,
such as the linker path: `-L $GPERFTOOLS_HOME/lib/`.

:::::

::::: {#optional-hwloc .optional}

**Optional:** Dealing with NUMA

If your test machine is a NUMA machine, then we recommend that, for
best performance on benchmarks, you configure the benchmarks to use
the round-robin page-allocation for NUMA. The existing benchmarking
framework automatically handles this configuration, if the benchmarks
are linked with a library called `hwloc`. As such, to run experiments
on a NUMA machine, we recommend that you insert into the file
`encore/bench/settings.sh` the following line.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
USE_HWLOC=1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Of course, `hwloc` needs to be installed on the test system for the
benchmarks to build with this configuration. Fortunately, it is easy
to check whether `hwloc` is installed: just run the following command,
and if successful, you should see output somewhat like below.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ pkg-config --cflags hwloc
-I/nix/store/lwjvcas5sxs4r3m3r780zkjc4h8a39pb-hwloc-1.11.8-dev/include
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:::::

The script supports running one benchmark at a time. Let's start by
running the convexhull benchmark. Let `$P` denote the number of
processors/cores that you wish to use in the experiments. This number
should be at least two and should be no more than the number of cores
in the system.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bench.pbench compare -benchmark convexhull -proc 1,$P
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::::: {#note-hyperthreading .note}

*Note:* If your machine has hyperthreading enabled, then we recommend
running the experiments without and with hyperthreading. To run with
hyperthreading, just set `$P` to be the total number of cores or
hyperthreads in the system as desired. For example, if the machine has
eight cores, with each core having two hyperthreads, then to test
without hyperthreading, set `$P` to be `8`, and to test with
hyperthreading, set `$P$` to be `16`.

:::::

For a variety of reasons, one of the steps involved in the
benchmarking can fail. A likely cause is the failure to obtain the
required input data. The reason is that these files are large, and as
such, we are hosting the files ourselves, using a peer-to-peer
file-transfer protocol called [IPFS](http://ipfs.io). 

::::: {#note-ipfs-ping .note}

*Note:* If you notice that the benchmarking script gets stuck for a
long time while issuing the `ipfs get ...` commands, we recommend
that, in a separate window, you ping one of the machines that we are
using to host our input data.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ ipfs ping QmRBzXmjGFtDAy57Rgve5NbNDvSUJYeSjoGQkdtfBvnbWX
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Please email us if you have to wait for a long time or are having
trouble getting the input data. If IPFS becomes problematic, we are
happy to find other means to distribute the input data.

:::::

How to run the experiments
--------------------------

After this step completes successfully, there should appear in the
`bench` folder a number of new text files of the form `results_*.txt`
and a PDF named `tables_compare.pdf`. The results in the table are,
however, premature at the moment, because there are too few samples to
make any conclusions.

It is possible to collect additional samples by running the following
command.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bench.pbench compare -benchmark convexhull -proc $P -runs 29 -mode append
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::::: {#note-samples .note}

*Note:* In our example, we collect additional samples for runs
involving two or more processors. The reason is that the single-core
runs usually exhibit relatively little noise and, as such, we prefer
to save time running experiments by performing fewer single-core runs.

:::::

So far, we have run only the `convexhull` benchmarks. All the other
benchmarks featured in the paper are also available to run.

- `radixsort`
- `samplesort`
- `suffixarray`
- `removeduplicates`
- `convexhull`
- `nearestneighbors`
- `delaunay`
- `raycast`
- `mst`
- `spanning`

As such, we can run `mst` and `spanning` as follows.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bench.pbench compare -benchmark mst,spanning -proc 1,$P
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Or, alternatively, we can just run all of the benchmarks.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bench.pbench compare -proc 1,$P
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

How to interpret the results
----------------------------

After running the benchmarks, the raw results that were collected from
each benchmark run should appear in text files in the `encore/bench`
folder. These results are fairly human readable, but the more
efficient way to interpret them is to look at the table. In the same
directory, there should now appear a file named
`tables_compare.pdf`. This table should look similar to the one given
in [@HEARTBEAT_18]. The source for the table can be found in
`encore/bench/_results/latex.tex`.

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Adrien Guatto](https://www.di.ens.fr/~guatto/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)
- [Filip Sieczkowski](https://sites.google.com/a/cs.uni.wroc.pl/efes/)

References
==========