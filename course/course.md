% mini-course on parallel programming
% Introduction to parallel computing in C++ with [pasl](http://deepsea.inria.fr/pasl)
% [Deepsea project](http://deepsea.inria.fr/)

Overview
========

The goal of this mini-course is to introduce the participant to the
following.

- The basic concepts of parallel computing.
- Some basic parallel algorithm design principles and techniques.
- Real-world performance and efficiency concerns in writing parallel
software and techniques for dealing with them.
- Parallel programming in C++.

For parallel programming in C++, we use a library, called
[pasl](http://deepsea.inria.fr/pasl/), that we have been developing
over the past 5 years. The implementation of the library uses advanced
scheduling techniques to run parallel programs efficiently on modern
multicores and provides a range of utilities for understanding the
behavior of parallel programs.

We chose the name Parallel Algorithm Scheduling Library because the
corresponding acronym, namely pasl, sounds a little like the French
phrase "pas seul", meaning "not alone".

By following the instructions in this minibook, we expect that the
reader will be able to write performant parallel programs at a
relatively high level (essentially at the same level of C++ code)
without having to worry too much about lower level details such as
machine specific optimizations that might be otherwise needed.


Book and associated materials
=============================

## Introduction to parallel computing in C++ with pasl

[@intro-parallelism-cpp]

[pdf](book.pdf)
[html](book.html)
[sources](https://github.com/deepsea-inria/pasl/tree/edu)

Credits
=======

Some of the material is based on, and sometimes directly borrows from,
an undergraduate course, 15-210, co-taught with [Guy
Blelloch](http://www.cs.cmu.edu/~./blelloch/) at CMU [@AB-book]. The
interested reader can find more details on parallel algorithm design
in the book [developed for this
course](http://www.parallel-algorithms-book.com/).

One important difference from the 15-210 material and the book is that
we use a functional language in that course, whereas these notes are
based an a lower-level C++ library for parallelism.

Using C++ allows us to discuss efficiency and performance concerns in
parallel computing on modern multicore machines.

We thank the faculty and staff of the [University of Puerto Rico
Computer Science Department](http://www.uprrp.edu/) for inviting us to
give lectures from these notes in November 2014 and for providing us
with feedback that we used to improve our course materials.

Team
====

- [Umut Acar](http://www.umut-acar.org/site/umutacar/)
- [Arthur Charguéraud](http://www.chargueraud.org/)
- [Mike Rainey](http://gallium.inria.fr/~rainey/)

Collaborators
=============

- Vitaly Aksenov
- [Guy Blelloch](http://www.cs.cmu.edu/~./blelloch/)
- [Edusmildo Orozco Salcedo](http://ccom.uprrp.edu/professor.php?pid=14)
- [R. Arce Nazario](http://ccom.uprrp.edu/~rarce/ditto/)

References
==========

Get the [bibtex file](course.bib) used to generate these
references.
