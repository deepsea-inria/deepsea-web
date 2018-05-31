% A work-efficient algorithm for parallel unordered depth-first search
% Deepsea project
% November 2015

Overview
========

This project concerns high-performance parallel graph traversal (or,
graph search) over directed, in-memory graphs using shared-memory,
multiprocessor machines (aka multicore). The main research question
addressed by this project is the following:

> *Can we design asymptotically and practically algorithms for the
> efficient traversal of in-memory directed graphs? Furthermore, can
> we design such algorithms so that, for any input graph, the cost of
> load balancing is negligible, yet the amount of parallelism being
> utilized is close to the hard limit imposed by the input graph and
> the machine?*

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

- [Page on ACM Digital Library](http://dl.acm.org/citation.cfm?id=2807651)
- [Article](http://chargueraud.org/research/2015/pdfs/pdfs_sc15.pdf)
- [Slides from talk](http://gallium.inria.fr/~rainey/slides/sc15-pdfs-talk.pdf)
- [Video copy of talk](https://www.youtube.com/watch?v=kOausvmMtmM)

Run our experimental evaluation
===============================

The source code we used for our experimental evaluation is hosted by a
[Github repository](https://github.com/deepsea-inria/sc15-pdfs). The
source code for our PDFS and our implementation of the DFS of Cong et
al is stored in the file named
[dfs.hpp](https://github.com/deepsea-inria/sc15-pdfs/blob/master/sc15-graph/graph/include/dfs.hpp).

Prerequisites
----------------

To have enough room to run the experiments, your filesystem should
have about 300GB of free hard-drive space and your machine at least
128GB or RAM. These space requirements are so large because some of
the input graphs we use are huge.

We use the [nix package manager](https://nixos.org/nix/download.html)
to handle the details of our experimental setup. The first step is to
install nix on your machine.

Obtaining experimental data
---------------------------

Now, we need to first obtain the source code of pdfs.

~~~~
$ git clone https://github.com/deepsea-inria/sc15-pdfs.git
$ cd sc15-pdfs/script
~~~~

If there is sufficient free space on the current file system, then
simply run the following command.

~~~~
$ nix-build
~~~~

Otherwise, to use a different path, run the following.

~~~~
$ nix-build --argstr pathToData <path to folder to store graph data>
~~~~

To streamline this process, we are going to add the benchmarking
folder to our path.

~~~~
$ export PATH=`pwd`/results/bench/:$PATH
~~~~

We can now start generating the graph data. This process requires
access to a fast internet connection and likely a few hours to
complete. If there are any issues with the download, please contact
the authors for help.

~~~~
$ graph.pbench generate -size large
~~~~

Running the experiment
-------------------------

The first series of benchmark runs gather data to serve as baseline
measurements. 

~~~~
$ graph.pbench baselines -size large
~~~~

The next command that needs to be run collects data for each graph to
determine the number of vertices reachable from the source vertex.

~~~~
$ graph.pbench accessible -size large -skip plot
~~~~

After the command completes, the results of the experiment are going
to be stored in the `_results` folder.

We are now ready to run the main body of experiments. The following
command starts the experiments running.

~~~~
$ graph.pbench overview -size large -skip plot -runs 30 
~~~~

To achieve clean results, we recommend performing thirty
runs. However, it may be faster to perform just a few at first, and
then collect more data later, next time passing to `graph.pbench` the
flag `-mode append`.

Analyzing the results
------------------------

After running the experiments, the raw result data should be stored in
new files named `results_accessible_large.txt`,
`results_baselines_large.txt`, and `results_overview_large.txt`. If
the experiments completed successfully, then the kind of plots that
appear in our SC'15 paper can be generated by the following command.

~~~~
$ graph.pbench overview -size large -runs 30 -sub graphs,main,locality
~~~~

After completion, the file named `table_graphs.pdf` should contain a
table that bears resemblance to Table 1 in our SC'15 paper. The file
named `_results/table_graphs.tex` contains the source code. A speedup
plot, like the one in Figure 6, should appear in a new file named
`plot_main.pdf` (with souce code in
`_results/plot_main.pdf-all.r`). The plot corresponding to Figure 8 in
the paper, namely, the locality study, should appear in the file named
`plots_overview_locality_large.pdf` (with souce code in
`plots_overview_locality_large.pdf-all.r`).


Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

References
==========

Get the [bibtex file](pdfs.bib) used to generate these
references.

[^1]: [@PDFS_15]
