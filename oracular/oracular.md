% oracular scheduling
% Controlling granularity automatically in implicitly parallel languages
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

One central difficulty in parallelism is to spawn sequential subtasks
of the right size. On the one hand, creating sequential tasks that are
too small leads to unacceptable overheads. On the other hand, creating
sequential tasks that are too big caps the number of cores that can be
used.

The traditional approach to granularity control consists in deciding
whether to sequentialize subtasks or not based on a cutoff value
hard-coded in the source code. Unfortunately, this approach is not
portable. Another approach is auto-tuning, which consists in
automatically trying various possible values for the cutoff on a given
hardware. But this approach takes time and usually involves collecting
samples offline of input data. The goal of our work is thus to come up
with a portable, online approach to granularity control.

Contribution
============

We have developed a new approach to granularity control that combines
asymptotic complexity annotations with runtime profiling. We require
the programmer to annotate their parallel functions with an asymptotic
complexity expression. We then use runtime profiling for deducing the
constant factors that apply. Using this information, we are able to
predict execution time and enforce our scheduling policy: any subtask
that is predicted to take less than a fixed amount of time gets
sequentialized. This approach works for any divide-and-conquer
algorithm whose worst-case complexity matches its average complexity.

We have proved bounds showing that our granularity control strategy
leads to provably-good parallel run times. Moreover, we have
implemented our approach and shown that it works well in practice.

Implementation
==============

We first implemented these ideas in the [Manticore
compiler](http://manticore.cs.uchicago.edu/) (SML syntax), as a
source-to-source translation. We later re-implemented them in our C++
library [pasl](http://deepsea.inria.fr/pasl/), where asymptotic cost
annotations are to be provided in the form of member functions of the
closure objects.

Related research publications
=============================

## Oracle Scheduling: Controlling Granularity in Implicitly Parallel Languages

[@acar-chargueraud-rainey-11-oracle]

[paper](oracle_scheduling.pdf)
[slides](2011_10_26_talk_oopsla_oracle.pdf)


Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

Collaborators
=============

- Vitaly Aksenov
- Anna Malova

References
==========

Get the [bibtex file](oracular.bib) used to generate these
references.
