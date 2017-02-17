% Purely functional chunked sequences
% Deepsea
% February 2017

Introduction
============

~~~~~ {.ocaml}
let K = 32
~~~~~

***Sequence notation.*** We are going to use the usual mathematical
notation for sequences: the sequence `xs = [x₀, ..., xₙ]` contains `n
+ 1` elements, starting with `x₀` and ending with `xₙ`. Given two
sequences, `xs = [x₀, ..., xₙ]` and `xs = [y₀, ..., yₘ]`, we denote
the concatenation by `xs ⊕ ys = [x₀, ..., xₙ, y₀, ..., yₘ]`.

***Abstract data type.***

~~~~~ {.ocaml}
type α chunkedseq

size [x₀, ..., xₙ]   : α chunkedseq → int = n + 1
sub (xs₁ ⊕ [xᵢ] ⊕ xs₂ , i)
                     : α chunkedseq ✕ int → α = xᵢ
  such that size xs₁ = i
back (xs ⊕ [x])      : α chunkedseq → α = x
front ([x] ⊕ xs)     : α chunkedseq → α = x
push_front (xs, x)   : α chunkedseq ✕ α → α chunkedseq = [x] ⊕ xs
push_back (xs, x)    : α chunkedseq ✕ α → α chunkedseq = xs ⊕ [x]
pop_front ([x] ⊕ xs) : α chunkedseq → (α chunkedseq ✕ α) = (xs, x)
pop_back (xs ⊕ [x]   : α chunkedseq → (α chunkedseq ✕ α) = (xs, x)
concat (xs₁, xs₂)    : α chunkedseq ✕ α chunkedseq → α chunkedseq = xs₁ ⊕ xs₂
split (xs₁ ⊕ [xᵢ] ⊕ xs₂, i)
                     : α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
                         = (xs₁, xᵢ, xs₂)
  such that size xs₁ == i
~~~~~

Chunk
=====

***Weight.***

~~~~~ {.ocaml}
type weight = int
~~~~~

~~~~~ {.ocaml}
type α wf = (α → int)
~~~~~

The simplest weight function assigns to each item the same weight:
one.

~~~~~ {.ocaml}
(λ x . 1) : α wf
~~~~~

***Fixed-capacity buffer.*** A chunk represents a storage space with
   capacity for up to `K` items of a given type. Given a
   fixed-capacity buffer `b`, the result of the call `|b|` yields the
   number of items `0 ≤ n ≤ K` stored in `b`.

~~~~~ {.ocaml}
type (α, K) fixed_capacity_buffer
~~~~~

It is often useful to take the sum of the weights of a given
buffer. For this purpose, we define the function `Σ`. The function
itself takes as argument a weight function `wf` and yields the
combined weights of the items in the given buffer.

~~~~~ {.ocaml}
Σ wf [x₀, ..., xₙ] : α wf → (α, K) fixed_capacity_buffer → int
                   = (wf x₀) + ... + (wf xₙ)
~~~~~

***Abstract data type.***

~~~~~ {.ocaml}
type α chunk = weight ✕ (α, K) fixed_capacity_buffer

size (_, [x₀, ..., xₙ])    : α chunk → int = n + 1
sub ((_, xs₁ ⊕ [xᵢ] ⊕ xs₂) , i)
                           : α chunk ✕ int → α = xᵢ
  such that |xs₁| == i
back (_, xs ⊕ [x])         : α chunk → α = x
front (_, [x] ⊕ xs)        : α chunk → α = x
push_front wf (w, xs, x)   : α wf → α chunk ✕ α → α chunk = (w, [x] ⊕ xs)
  such that w == Σ wf ([x] ⊕ xs)
push_back wf (w, xs, x)    : α wf → α chunk ✕ α → α chunk = (w, xs ⊕ [x])
  such that w == Σ wf (xs ⊕ [x])
pop_front wf (w, [x] ⊕ xs) : α wf → α chunk → (α chunk ✕ α) = ((w, xs), x)
  such that w == Σ wf xs
pop_back wf (w, xs ⊕ [x])  : α wf → α chunk → (α chunk ✕ α) = ((w, xs), x)
  such that w == Σ wf xs
concat wf ((w₁, xs₁), (w₂, xs₂))
                            : α wf → α chunk ✕ α chunk → α chunk
                            = (w₁ + w₂, xs₁ ⊕ xs₂)
  such that w₁ + w₂ == Σ wf xs₁ + Σ wf xs₂
split wf (w, xs₁ ⊕ [xᵢ] ⊕ xs₂, i)
                            : α chunk ✕ int → (α chunk ✕ α ✕ α chunk)
                            = ((w₁, xs₁), xᵢ, (w₂, xs₂))
  where w₁ = Σ wf xs₁
        w₂ = Σ wf xs2
  such that |xs₁| == i
~~~~~

~~~~~ {.ocaml}
weight (w, _)               : α chunk → int = w
tabulate wf (n, f)          : α wf → int ✕ (int → α) → α chunk = (Σ wf xs, xs)
  where xs = [f 0, ..., f (n - 1)]
~~~~~

~~~~~ {.ocaml}
ec : α wf → chunk
ec wf = tabulate wf (0, λ x. 1)
~~~~~

~~~~~ {.ocaml}
empty : α chunk → bool
empty c = (size c == 0)

full : α chunk → bool
full c = (size c == K)
~~~~~

Chunked sequence
================

Representation
--------------

~~~~~ {.ocaml}
type α chunkedseq
  = Shallow of α chunk
  | Deep of int ✕ α deep

type α deep = {
  fₒ : α chunk, fᵢ : α chunk,
  m : (α chunk) chunkedseq,
  bᵢ : α chunk, bₒ : α chunk
}
~~~~~

Smart constructors
------------------

~~~~~ {.ocaml}
mk_deep : α wf → α deep → α chunkedseq
mk_deep wf (d as {fₒ, fᵢ, m, bᵢ, bₒ}) =
  let w = Chunk.weight fₒ + Chunk.weight fᵢ
        + weight m
        + Chunk.weight bᵢ + Chunk.weight bₒ
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
check wf (d as Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ})) =
  let sz = Chunk.size fₒ + Chunk.size fᵢ
         + Chunk.size bᵢ + Chunk.size bₒ
  in
  if sz == 0 && ¬ (empty m) then
    mk_deep wf {fₒ=pop_front m, fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ}
  else if sz ≤ 1 && empty m then
    mk_shallow' wf (fₒ, fᵢ, bᵢ, bₒ)
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
push_front' : α wf → α chunkedseq ✕ α → α chunkedseq
push_front' wf (Shallow c) x =
  if Chunk.full c then
    let m = Shallow (ec wf) in
    push_front' wf (mk_deep wf {fₒ=ec wf, fᵢ=ec wf, m=m, bᵢ=ec wf, bₒ=c}, x)
  else
    Shallow (Chunk.push_front wf (c, x))
push_front' wf (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ})) =
  if Chunk.full fₒ then
    if Chunk.empty fᵢ then
      push_front' wf (mk_deep wf {fₒ=fᵢ, fᵢ=fₒ, m=m, bᵢ=bᵢ, bₒ=bₒ}, x)
    else
      let m' = push_front' (Σ weight) (m, fᵢ) in
      push_front' wf (mk_deep wf {fₒ=ec wf, fᵢ=fₒ, m=m', bᵢ=bᵢ, bₒ=bₒ}, x)
  else
    let fₒ' = Chunk.push_front wf (fₒ, x) in
    mk_deep wf {fₒ=fₒ', fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ}
~~~~~

Pop
---

~~~~~ {.ocaml}
pop_front' : α wf → α chunkedseq → (α chunkedseq ✕ α)
pop_front' wf (Shallow c) =
  let (c', x) = Chunk.pop_front wf c in
  (Shallow c', x)
pop_front' wf (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ})) =
  if Chunk.empty fₒ then
    if ¬ (Chunk.empty fᵢ) then
      pop_front' wf (mk_deep' wf {fₒ=fᵢ, fᵢ=fₒ, m=m, bᵢ=bᵢ, bₒ=bₒ})
    else if ¬ (empty m) then 
      let (m', c) = pop_front' (Σ weight) m in
      pop_front' wf (mk_deep' wf {fₒ=c, fᵢ=fᵢ, m=m', bᵢ=bᵢ, bₒ=bₒ})
    else if ¬ (Chunk.empty bᵢ) then
      pop_front' wf (mk_deep' wf {fₒ=bₒ, fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=fₒ})
    else
      let (bₒ', x) = Chunk.pop_front wf bₒ in
      (mk_deep' wf {fₒ=fₒ, fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ'}, x)
  else
    let (fₒ', x) = Chunk.pop_front wf fₒ in
    (mk_deep' wf {fₒ=fₒ', fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ}, x)
~~~~~

Concatenation
-------------

~~~~~ {.ocaml}
push_buffer_back : α wf → α chunkedseq ✕ α chunk → α chunkedseq
push_buffer_back wf (s, c)  =
  if Chunk.empty c then s
  else push_buffer_back' wf (s, c)

push_buffer_back' wf (Shallow c', c)  =
  mk_deep' wf {fₒ=c', fᵢ=ec wf, m=Shallow (ec wf), bᵢ=ec wf, bₒ=c}
push_buffer_back' wf (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ}), c)  =
  if Chunk.weight c + Chunk.weight bₒ ≤ K then
    let bₒ' = Chunk.concat wf (bₒ, c) in
    mk_deep' wf {fₒ=fₒ, fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ'}
  else
    let m' =
      if Chunk.empty bᵢ then m
      else push_buffer_back (Σ weight) (m, bᵢ)
    in
    mk_deep' wf {fₒ=fₒ, fᵢ=fᵢ, m=m', bᵢ=ec wf, bₒ=c}
~~~~~

~~~~~ {.ocaml}
concat' : α wf → α chunkedseq ✕ α chunkedseq → α chunkedseq
concat' wf (Shallow c₁, s₂) =
  push_buffer_front wf (c₁, s₂)
concat' wf (s₁, Shallow c₂) =
  push_buffer_back wf (s₁, c₂)
concat' wf (s₁ as Deep (_, {fₒ=fₒ₁, fᵢ=fᵢ₁, m=m₁, bᵢ=bᵢ₁, bₒ=bₒ₁}),
            s₂ as Deep (_, {fₒ=fₒ₂, fᵢ=fᵢ₂, m=m₂, bᵢ=bᵢ₂, bₒ=bₒ₂})) =
  let m₁' = push_buffer_back wf (m₁, bᵢ₁) in
  let m₁'' = push_buffer_back wf (m₁', bₒ₁) in
  let m₂' = push_buffer_front wf (m₂, fᵢ₂) in
  let m₂'' = push_buffer_front wf (m₂', fₒ₂) in
  if empty s₁ then
    s₂
  else if empty s₂ then
    s₁
  else
    let (c₁, c₂) = (back m₁'', front m₂'') in
    let (m₁''', m₂''') = 
      if Chunk.weight c₁ + Chunk.weight c₂ ≤ K then
        let (m₁'', _) = pop_back' wf m₁'' in
        let (m₂'', _) = pop_back' wf m₂'' in
        let c' = Chunk.concat wf (c₁, c₂) in
        (push_back' (m₁'', c'), m₂'')
      else
        (m₁'', m₂'')
    let m₁₂ = concat' (Σ weight) (m₁''', m₂''') in
    mk_deep' wf {fₒ=fₒ₁, fᵢ=fᵢ₁, m=m₁₂, bᵢ=bᵢ₂, bₒ=bₒ₂}
~~~~~

Weighted split
--------------

~~~~~ {.ocaml}
split' : α wf → α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
split' wf (Shallow c, i) =
  let (c₁, x, c₂) = Chunk.split wf (c, i) in
  (Shallow c₁, x, Shallow c₂)
split' wf (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ})) =
  let (wfₒ, wfᵢ) = (Chunk.weight fₒ, Chunk.weight fᵢ) in
  let wₘ = weight m in
  let (wbᵢ, wbₒ) = (Chunk.weight bᵢ, Chunk.weight bₒ) in
  let (s₁, x, s₂) = 
    if i ≤ wfₒ then
      let (fₒ₁, x, fₒ₂) = Chunk.split wf (fₒ, i) in
      let s₁ = mk_deep wf {fₒ=fₒ₁, fᵢ=ec wf, m=Shallow (ec wf),
                           bᵢ=ec wf, bₒ=ec wf}
      in
      let s₂ = mk_deep wf {fₒ=fₒ₂, fᵢ=fᵢ, m=m, bᵢ=bᵢ, bₒ=bₒ} in
      (s₁, x, s₂)
    else if i ≤ wfₒ + wfᵢ then
      let (fᵢ₁, x, fᵢ₂) = Chunk.split wf (fᵢ, i) in
      let s₁ = mk_deep wf {fₒ=fₒ, fᵢ=ec wf, m=Shallow (ec wf),
                           bᵢ=ec wf, bₒ=fᵢ₁} in
      let s₂ = mk_deep wf {fₒ=fᵢ₂, fᵢ=ec wf, m=m, bᵢ=bᵢ, bₒ=bₒ} in
      (s₁, x, s₂)
    else if i ≤ wfₒ + wfᵢ + wₘ then
      let j = i - wfₒ - wfᵢ in
      let (m₁, c, m₂) = split' (Σ weight) (m, j) in
      let (c₁, x, c₂) = Chunk.split wf (c, j - weight m₁) in
      let s₁ = mk_deep wf {fₒ=fₒ, fᵢ=fᵢ, m=m₁, bᵢ=ec wf, bₒ=c₁} in
      let s₂ = mk_deep wf {fₒ=c₂, fᵢ=ec wf, m=m₂, bᵢ=bᵢ, bₒ=bₒ} in
      (s₁, x, s₂)
    else if i ≤ wfₒ + wfᵢ + wₘ + wbᵢ then
      ...
    else
      ...
  in
  (check wf s₁, x, check wf s₂)
~~~~~

Summary
=======

~~~~~ {.ocaml}
sub xs = ...

size xs = weight xs

back xs = ...

front xs = ...

let wf₀ : α wf = (λ x . 1)

push_front = push_front' wf₀
push_back = push_back' wf₀
...
split = split' wf₀
~~~~~
