% A duality between parallel futures and async/finish
% [Mike Rainey](http://gallium.inria.fr/~rainey/);
  [Filip Sieczkowski](http://cs.au.dk/~filips/)
% 18 March 2015

Introduction
============

Parallel futures and async/finish are two important and well-studied
forms of *implicit parallelism*.

Implicit parallelism is a style of parallel programming whereby
*opportunities* for parallel execution are specified in the program
text.

It is the job of the language implementation (i.e., compiler and
runtime) to realize parallelism where parallelism is profitable.

The purpose of implicit parallelism is to give the programmer some
limited control to change the low-level details of their program
(e.g., scheduling and synchronization), leaving the most of the
details to be handled by the language implementation.

The advantage is that the programmer gets to write code at a higher
level of abstraction, thereby easing the job of program design,
testing, and verification.

At first glance, parallel futures and async/finish may seem to be
quite different and, moreover, to be related in no interesting way.

Although these two constructs have received much attention in the
research literature, to the best of our knowledge, no study has yet
compared the two.

In this short article, we do just that: we show that there exists a
certain duality between futures and async/finish and that this duality
captures why each of these two constructs are useful in their own
right.

To capture the duality precisely, we need to go deeper than the
surface syntax and informal descriptions that are often used to
describe the constructs.

What we do instead is describe an encoding of each of the two
constructs in a particular abstract machine that we have presented in
prior work [@damp:efficient-scheduling-primitives]

This abstract machine that we are going to use is one that models
computation as a dynamically unfolding directed acyclic graph (i.e.,
DAG).

It turns out that our dynamic DAG machine is at just the right level
of abstraction for us to see the duality.

We structure the rest of this article as follows.

First, we describe futures and async/finish at a high level.

Second, we describe our dynamic DAG machine and the encodings of the
two constructs.

Finally, we identify the duality by examining the encodings side by
side.

Parallel futures
================

> Filip: please write a brief description of futures a la functional
> programming. The Blelloch and Reid-Miller paper is the authoritative
> source [@blelloch-futures].

> After we cover the general case, let us narrow the focus a little to
> a special case of parallel futures: namely, parallel pipelines. The
> example we give for futures will be a more imperative style, since I
> believe that this style is more in keeping with this
> description. Let's use the x264 algorithm as the example for
> futures, in fact. We can borrow the pseudocode from the Cilk Piper
> paper [@cilk-pipeline].

> Filip: please simplify and present the x264 algorithm, which you can
> find in Figure 2 of [@cilk-pipeline].

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
x264()
  // todo: example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Async/finish
============

Compared to futures, async/finish is a relatively new language
construct.

The first paper describing async/finish is one of the early papers on
the X10 programming language, which is a parallel dialect of Java
[@x10-async-finish].

At the surface-language level, the construct consists of two syntactic
forms: `async` and `finish`.

The former spawns a new parallel thread and the latter terminates a
specified set of parallel threads.

The following code snippet shows how one can use async/finish to solve
the graph-connectivity problem using a DFS-like traversal order.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void dfs(int v)
  already = cas(&visited[n], false, true)
  if not(already)
    nb_visited[my_proc_id]++
    foreach n in neighbors v
      async dfs(n)

void main()
  finish {
    dfs(source)
  }
  nb_accessible_from_source = sum(nb_visited)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The result of this program is a number which counts the vertices that
are reachable from the `source` vertex.

Now, let's consider the implementation in detail.

The `dfs` function takes a source vertex `v` as argument.

When it examines `v`, the `dfs` function does one of two things.

If `v` is already visited, then `dfs` returns.

Otherwise, `dfs` recursively visits each of the subgraphs that are
rooted at each neighbor `n` of `v`.

Each time it visits a vertex, `dfs` increments a counter cell, namely
`nb_visited[my_proc]`, which is a cell that is private to the calling
processor.

To ensure a correct count of reachable vertices, the program needs to
ensure that each reachable vertex is visited once and only once.

It ensures this property thanks to the use of the atomic
compare-and-swap instruction (i.e., `cas`), which atomically updates
the `visited` array as the traversal proceeds.

After being spawned by an `async`, each recursive call runs in
parallel with all the other currently running recursive calls.

Note that, although they *can* run in parallel, it does not
necessarily mean that an implementation can or should try to make all
the calls to `dfs` run in parallel.

The `async` is merely a hint in the program text that gets passed by
the compiler to a load-balancing algorithm; the hint simply tells the
load-balancing algorithm that there exists a specified opportunity for
parallelism.

Indeed, it is often the case that an efficient load-balancing
algorithm, such as work stealing, performs the majority of nearby
`async` calls in a sequential fashion.

Finally, the `finish` block ensures that all calls to `dfs` terminate
before the program can compute the value of
`nb_accessible_from_source`.

The dynamic DAG machine
=======================

In our dynamic DAG machine, a running computation is represented by a
DAG that unfolds as the program executes.

A vertex in the DAG corresponds to an instruction and an edge to a
control or data dependency.

> Filip: please work to fill the missing material below, providing
> some diagrams, if the mood should strike you.

> We can take a lot of material for this section from my
> [talk](http://gallium.inria.fr/~rainey/slides/lame2013.pdf).

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vertex* create_vertex(closure*)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void add_vertex(vertex*)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void add_edge(vertex*, vertex*)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void transfer_outedges_to(vertex*)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Encoding futures
----------------

Encoding async/finish
---------------------

The duality
===========

What futures provide is a mechanism whereby we can activate a thread
such that:

- that thread produces some data, and
- that data can be demanded concurrently by zero or more consumer
  threads.

Furthermore, futures enable dependency edges from a consumer to a
producer to be created *on the fly*.

What async/finish provides is a mechanism whereby we can
(asynchronously) activate a collection of parallel threads such that:

- each thread produces some data, and
- that data can be demanded all at once by a single consumer thread.

Furthermore, async/finish enables dependency edges from a producer
to the consumer to be created *on the fly*.

In other words, with futures, we can create networks of processes in
which there is a single producer and multiple consumers, whereas with
async/finish, we can create a network where there are multiple
producers and a single consumer.

In both constructs, we have the flexibility to add dependency edges on
the fly.

That is the duality.

Relation to fork/join
=====================

It turns out that, in our DAG model, futures and async/finish have
both relate in a straightforward fashion to fork/join parallelism.

In particular, one can view fork/join as a special case of either
futures or async/finish where (1) each branching point in the DAG can
be deduced from a corresponding fork instruction in the program text
and (2) the branching factor corresponding to a branching point is a
fixed constant (that is specified in the program text).

In other words, on one hand, in fork/join, dependency edges *cannot*
be added to the DAG on the fly (i.e., after the given fork/join
threads are spawned).

On the other hand, for example, with futures, a dependency edge can be
added on a thread while the thread is running.

It is this ability to add edges on the fly in this fashion that
distinguishes futures and async/finish from basic fork/join.

Summary
=======

> TODO

References
==========

Get the [bibtex file](dag.bib) used to generate these references.
