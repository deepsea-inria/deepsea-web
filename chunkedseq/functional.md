% Purely functional chunked sequences
% Deepsea
% February 2017

Introduction
============

~~~~~ {.ocaml}
let K = 32
~~~~~

~~~~~ {.ocaml}
type α chunkedseq

sub      : α chunkedseq ✕ int → α
size     : α chunkedseq → int
weight   : α chunkedseq → int

type α wf = (α → int)

back       : α chunkedseq → α
front      : α chunkedseq → α
push_front : α wf → α chunkedseq ✕ α → α chunkedseq
pop_front  : α wf → α chunkedseq → (α chunkedseq ✕ α)
push_back  : α wf → α chunkedseq ✕ α → α chunkedseq
pop_back   : α wf → α chunkedseq → (α chunkedseq ✕ α)
concat     : α wf → α chunkedseq ✕ α chunkedseq → α chunkedseq
split      : α wf → α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
~~~~~

Chunk
=====

~~~~~ {.ocaml}
type α chunk

sub      : α chunk ✕ int → α
size     : α chunk → int
weight   : α chunk → int

push_front : α wf → α chunk ✕ α → α chunk
pop_front  : α wf → α chunk → (α chunk ✕ α)
push_back  : α wf → α chunk ✕ α → α chunk
pop_back   : α wf → α chunk → (α chunk ✕ α)
split      : α wf → α chunk ✕ int → (α chunk ✕ α ✕ α chunk)
concat     : α wf → α chunk ✕ α chunk → α chunk

tabulate : α wf → int ✕ (int → α) → α chunk
~~~~~

~~~~~ {.ocaml}
empty : α chunk → bool
empty c = (size c == 0)

full : α chunk → bool
full c = (size c == K)
~~~~~

~~~~~ {.ocaml}
map : (α → β) → α chunk → β chunk
sum : (α → int) → α chunk → int
~~~~~

Chunked sequence
================

Representation
--------------

~~~~~ {.ocaml}
type α chunkedseq
  = Shallow of α chunk
  | Deep of int ✕ α deep

and α deep = {
  fo : α chunk, fi : α chunk,
  mid : (α chunk) chunkedseq,
  bi : α chunk, bo : α chunk
}
~~~~~

Smart constructors
------------------

~~~~~ {.ocaml}
mk_deep : α wf → α deep → α chunkedseq
mk_deep wf (d as {fo, fi, mid, bi, bo}) =
  let w = Chunk.weight fo + Chunk.weight fi
        + weight mid
        + Chunk.weight bi + Chunk.weight bo
  in
  Deep (w, d)
~~~~~    

The smart constructor shown below takes four chunks and returns a new
shallow chunked sequence. The main precondition is that three of the
four input chunks are nonempty. The smart constructor reuses this
nonempty chunk to make a new shallow level.

~~~~~ {.ocaml}
mk_shallow' : α wf → α chunk ✕ α chunk ✕ α chunk ✕ α chunk
  → α chunkedseq
~~~~~

Check
-----

~~~~~ {.ocaml}
check : α wf → α chunkedseq → α chunkedseq
check wf (Shallow c) = Shallow c
check wf (d as Deep (_, {fo, fi, mid, bi, bo})) =
  let sz = Chunk.size fo + Chunk.size fi
         + Chunk.size bi + Chunk.size bo
  in
  if sz == 0 && ¬ (empty mid) then
    mk_deep wf {fo=pop_front mid, fi=fi, mid=mid, bi=bi, bo=bo}
  else if sz ≤ 1 && empty mid then
    mk_shallow' wf (fo, fi, bi, bo)
  else
    d
~~~~~

~~~~~ {.ocaml}
mk_deep' : α wf → α deep → α chunkedseq
mk_deep' wf d = check wf ∘ mk_deep
~~~~~

Push
----

~~~~~ {.ocaml}
ec : α wf → chunk
ec wf = Chunk.tabulate wf (0, λ x . x)
~~~~~

~~~~~ {.ocaml}
wf↑ : (α chunk) wf
wf↑ = Chunk.sum ∘ Chunk.map Chunk.weight
~~~~~

~~~~~ {.ocaml}
push_front : α wf → α chunkedseq ✕ α → α chunkedseq
push_front wf (Shallow c) x =
  if Chunk.full c then
    let mid = Shallow (ec wf) in
    push_front wf (mk_deep wf {fo=ec wf, fi=ec wf, mid=mid, bi=ec wf, bo=c}, x)
  else
    Shallow (Chunk.push_front wf (c, x))
push_front wf (Deep (_, {fo, fi, mid, bi, bo})) =
  if Chunk.full fo then
    if Chunk.empty fi then
      push_front wf (mk_deep wf {fo=fi, fi=fo, mid=mid, bi=bi, bo=bo}, x)
    else
      let mid' = push_front wf↑ (mid, fi) in
      push_front wf (mk_deep wf {fo=ec wf, fi=fo, mid=mid', bi=bi, bo=bo}, x)
  else
    let fo' = Chunk.push_front wf (fo, x) in
    mk_deep wf {fo=fo', fi=fi, mid=mid, bi=bi, bo=bo}
~~~~~

Pop
---

~~~~~ {.ocaml}
pop_front : α wf → α chunkedseq → (α chunkedseq ✕ α)
pop_front wf (Shallow c) =
  let (c', x) = Chunk.pop_front wf c in
  (Shallow c', x)
pop_front wf (Deep (_, {fo, fi, mid, bi, bo})) =
  if Chunk.empty fo then
    if ¬ (Chunk.empty fi) then
      pop_front wf (mk_deep' wf {fo=fi, fi=fo, mid=mid, bi=bi, bo=bo})
    else if ¬ (empty m) then 
      let (mid', c) = pop_front wf↑ mid in
      pop_front wf (mk_deep' wf {fo=c, fi=fi, mid=mid', bi=bi, bo=bo})
    else if ¬ (Chunk.empty bi) then
      pop_front wf (mk_deep' wf {fo=bo, fi=fi, mid=mid, bi=bi, bo=fo})
    else
      let (bo', x) = Chunk.pop_front wf bo in
      (mk_deep' wf {fo=fo, fi=fi, mid=mid, bi=bi, bo=bo'}, x)
  else
    let (fo', x) = Chunk.pop_front wf fo in
    (mk_deep' wf {fo=fo', fi=fi, mid=mid, bi=bi, bo=bo}, x)
~~~~~

Concatenation
-------------

~~~~~ {.ocaml}
push_buffer_back : α wf → α chunkedseq ✕ α chunk → α chunkedseq
push_buffer_back wf (s, c)  =
  if Chunk.empty c then s
  else push_buffer_back' wf (s, c)

push_buffer_back' wf (Shallow c', c)  =
  mk_deep' wf {fo=c', fi=ec wf, mid=Shallow (ec wf), bi=ec wf, bo=c}
push_buffer_back' wf (Deep (_, {fo, fi, mid, bi, bo}), c)  =
  if Chunk.weight c + Chunk.weight bo ≤ K then
    let bo' = Chunk.concat wf (bo, c) in
    mk_deep' wf {fo=fo, fi=fi, mid=mid, bi=bi, bo=bo'}
  else
    let mid' =
      if Chunk.empty bi then mid
      else push_buffer_back wf↑ (mid, bi)
    in
    mk_deep' wf {fo=fo, fi=fi, mid=mid', bi=ec wf, bo=c}
~~~~~

~~~~~ {.ocaml}
concat : α wf → α chunkedseq ✕ α chunkedseq → α chunkedseq
concat wf (Shallow c1, s2) =
  push_buffer_front wf (c1, s2)
concat wf (s1, Shallow c2) =
  push_buffer_back wf (s1, c2)
concat wf (s1 as Deep (_, {fo=fo1, fi=fi1, mid=mid1, bi=bi1, bo=bo1}),
           s2 as Deep (_, {fo=fo2, fi=fi2, mid=mid2, bi=bi2, bo=bo2})) =
  let mid1' = push_buffer_back wf (mid1, bi) in
  let mid1'' = push_buffer_back wf (mid1', bo) in
  let mid2' = push_buffer_front wf (mid2, fi) in
  let mid2'' = push_buffer_front wf (mid2', fo) in
  if empty s1 then
    s2
  else if empty s2 then
    s1
  else
    let (c1, c2) = (back mid1'', front mid2'') in
    let (mid1''', mid2''') = 
      if Chunk.weight c1 + Chunk.weight c2 ≤ K then
        let (mid1'', _) = pop_back wf mid1'' in
        let (mid2'', _) = pop_back wf mid2'' in
        let c' = Chunk.concat wf (c1, c2) in
        (push_back (mid1'', c'), mid2'')
      else
        (mid1'', mid2'')
    let mid12 = concat wf↑ (mid1''', mid2''') in
    mk_deep' wf {fo=fo1, fi=fi1, mid=mid12, bi=bi2, bo=bo2}
~~~~~

Weighted split
--------------

~~~~~ {.ocaml}
split : α wf → α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
split wf (Shallow c, i) =
  let (c1, x, c2) = Chunk.split wf (c, i) in
  (Shallow c1, x, Shallow c2)
split wf (Deep (_, {fo, fi, mid, bi, bo})) =
  let (wfo, wfi) = (Chunk.weight fo, Chunk.weight fi) in
  let wmid = weight mid in
  let (wbi, wbo) = (Chunk.weigth bi, Chunk.weight bo) in
  let (s1, x, s2) = 
    if i ≤ wfo then
      let (fo1, x, fo2) = Chunk.split wf (fo, i) in
      let s1 = mk_deep wf {fo=fo1, fi=ec wf, mid=Shallow (ec wf),
                           bi=ec wf, bo=ec wf}
      in
      let s2 = mk_deep wf {fo=fo2, fi=fi, mid=mid, bi=bi, bo=bo} in
      (s1, x, s2)
    else if i ≤ wfo + wfi then
      let (fi1, x, fi2) = Chunk.split wf (fi, i) in
      let s1 = mk_deep wf {fo=fo, fi=ec wf, mid=Shallow (ec wf),
                           bi=ec wf, bo=fi1} in
      let s2 = mk_deep wf {fo=fi2, fi=ec wf, mid=mid, bi=bi, bo=bo} in
      (s1, x, s2)
    else if i ≤ wfo + wfi + wmid then
      let j = i - wfo - wfi in
      let (mid1, c, mid2) = split wf↑ (mid, j) in
      let (c1, x, c2) = Chunk.split wf (c, j - weight m1) in
      let s1 = mk_deep wf {fo=fo, fi=fi, mid=m1, bi=ec wf, bo=c1} in
      let s2 = mk_deep wf {fo=c2, fi=ecwf, mid=m2, bi=bi, bo=bo} in
      (s1, x, s2)
    else if i ≤ wfo + wfi + wmid + wbi then
      ...
    else
      ...
  in
  (check wf s1, x, check wf s2)
~~~~~

Summary
=======