% Purely functional chunked sequences
% Deepsea
% February 2017

Introduction
============

Chunkedseq paper [^1] and Finger trees [^2]

***Sequence notation.*** We are going to use the usual mathematical
notation for sequences: the sequence `xs = [x₀, ..., xₙ]` contains `n
+ 1` elements, starting with `x₀` and ending with `xₙ`. Given two
sequences, `xs = [x₀, ..., xₙ]` and `xs = [y₀, ..., yₘ]`, we denote
the concatenation by `xs ⊕ ys = [x₀, ..., xₙ, y₀, ..., yₘ]`.

***Abstract data type.***

~~~~~ {.ocaml}
type α chunkedseq

[⋮⋮]                 : α chunkedseq = []
size [x₀, ..., xₙ]   : α chunkedseq → int = n + 1
sub (xs₁ ⊕ [xᵢ] ⊕ xs₂ , i)
                     : α chunkedseq ✕ int → α = xᵢ
  such that size xs₁ = i
back (xs ⊕ [x])      : α chunkedseq → α = x
front ([x] ⊕ xs)     : α chunkedseq → α = x
push_front (xs, x)   : α chunkedseq ✕ α → α chunkedseq = [x] ⊕ xs
push_back (xs, x)    : α chunkedseq ✕ α → α chunkedseq = xs ⊕ [x]
pop_front ([x] ⊕ xs) : α chunkedseq → (α chunkedseq ✕ α) = (xs, x)
pop_back (xs ⊕ [x])  : α chunkedseq → (α chunkedseq ✕ α) = (xs, x)
concat (xs₁, xs₂)    : α chunkedseq ✕ α chunkedseq → α chunkedseq = xs₁ ⊕ xs₂
split (xs₁ ⊕ [xᵢ] ⊕ xs₂, i)
                     : α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
                     = (xs₁, xᵢ, xs₂)
  such that size xs₁ = i
~~~~~

***Complexity.***



Chunk
=====

A chunk represents a storage space with capacity for up to `K` items
of a given type. Given a fixed-capacity buffer `b`, the result of the
call `|b|` yields the number of items `0 ≤ n ≤ K` stored in `b`.

~~~~~ {.ocaml}
type (α, K) fixed_capacity_buffer
~~~~~

***Weight.***

~~~~~ {.ocaml}
type weight = int

type α wf = (α → weight)
~~~~~

The simplest weight function assigns to each item the same weight:
one.

~~~~~ {.ocaml}
let γ₀ : α wf = (λ x . 1)
~~~~~

It is often useful to take the sum of the weights of a given
buffer. For this purpose, we define the function `Σ`. The function
itself takes as argument a weight function and yields the combined
weights of the items in the given buffer.

~~~~~ {.ocaml}
Σ f [x₀, ..., xₙ] : α wf → (α, K) fixed_capacity_buffer → int
                   = (f x₀) + ... + (f xₙ)
~~~~~

***Abstract data type.***

~~~~~ {.ocaml}
let K (* be an integer > 1; typically, 32 *)
type α chunk = weight ✕ (α, K) fixed_capacity_buffer

[⋮⋮]                        : α chunk = []
size (_, [x₀, ..., xₙ])    : α chunk → int = n + 1
sub ((_, xs₁ ⊕ [xᵢ] ⊕ xs₂) , i)
                           : α chunk ✕ int → α = xᵢ
  such that |xs₁| = i
back (_, xs ⊕ [x])         : α chunk → α = x
front (_, [x] ⊕ xs)        : α chunk → α = x
push_front γ ((w, xs), x)  : α wf → α chunk ✕ α → α chunk = (w', [x] ⊕ xs)
  where w' = γ x + Σ γ xs = γ x + w
push_back γ ((w, xs), x)   : α wf → α chunk ✕ α → α chunk = (w', xs ⊕ [x])
  where w' = γ x + Σ γ xs = γ x + w
pop_front γ (w, [x] ⊕ xs)  : α wf → α chunk → (α chunk ✕ α) = ((w', xs), x)
  where w' + γ x = Σ γ xs + γ x = w
pop_back γ (w, xs ⊕ [x])   : α wf → α chunk → (α chunk ✕ α) = ((w', xs), x)
  where w' + γ x = Σ γ xs + γ x = w
concat γ ((w₁, xs₁), (w₂, xs₂))
                           : α wf → α chunk ✕ α chunk → α chunk
                           = (w₁ + w₂, xs₁ ⊕ xs₂)
  such that w₁ + w₂ = Σ γ xs₁ + Σ γ xs₂
split γ ((w, xs₁ ⊕ [x] ⊕ xs₂), i)
                            : α chunk ✕ int → (α chunk ✕ α ✕ α chunk)
                            = ((w₁, xs₁), x, (w₂, xs₂))
  such that w₁ ≤ i < w₁ + γ x
  where w₁ = Σ γ xs₁ 
        w₂ = Σ γ xs₂
~~~~~

~~~~~ {.ocaml}
weight (w, _) : α chunk → int = w
~~~~~

~~~~~ {.ocaml}
empty : α chunk → bool
empty c = (size c = 0)

full : α chunk → bool
full c = (size c = K)
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
mk_deep : α deep → α chunkedseq
mk_deep (d as {fₒ, fᵢ, m, bᵢ, bₒ}) =
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
mk_shallow : α chunk ✕ α chunk ✕ α chunk ✕ α chunk
  → α chunkedseq
~~~~~

Push
----

~~~~~ {.ocaml}
push_front' : α wf → α chunkedseq ✕ α → α chunkedseq
push_front' γ (Shallow c, x) =
  if Chunk.full c then
    let m = Shallow [⋮⋮] in
    push_front' γ (mk_deep {fₒ=[⋮⋮], fᵢ=[⋮⋮], m=m, bᵢ=[⋮⋮], bₒ=c}, x)
  else
    Shallow (Chunk.push_front γ (c, x))
push_front' γ (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ} as d), x) =
  if Chunk.full fₒ then
    if Chunk.empty fᵢ then
      push_front' γ (mk_deep {d with fₒ=[⋮⋮], fᵢ=fₒ}, x)
    else
      let m' = push_front' Chunk.weight (m, fᵢ) in
      push_front' γ (mk_deep {d with fₒ=[⋮⋮], fᵢ=fₒ, m=m'}, x)
  else
    let fₒ' = Chunk.push_front γ (fₒ, x) in
    mk_deep {d with fₒ=fₒ'}
~~~~~

Check
-----

~~~~~ {.ocaml}
check : α wf → α chunkedseq → α chunkedseq
check γ (Shallow c) = assert false
check γ (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ}) as s) =
  let w = Chunk.weight fₒ + Chunk.weight fᵢ
        + Chunk.weight bᵢ + Chunk.weight bₒ
  in
  if w = 0 ∧ ¬ (empty m) then
    let (m', fₒ') = pop_front' Chunk.weight m in
    mk_deep {fₒ=fₒ', fᵢ=[⋮⋮], m=m', bᵢ=[⋮⋮], bₒ=[⋮⋮]}
  else if w = 1 ∧ empty m then
    mk_shallow (fₒ, fᵢ, bᵢ, bₒ)
  else if w = 0 ∧ empty m then
    Shallow [⋮⋮]
  else
    s
~~~~~

~~~~~ {.ocaml}
mk_deep' : α wf → α deep → α chunkedseq
mk_deep' γ = check γ ∘ mk_deep
~~~~~

Pop
---

~~~~~ {.ocaml}
pop_front' : α wf → α chunkedseq → (α chunkedseq ✕ α)
pop_front' γ (Shallow c) =
  let (c', x) = Chunk.pop_front γ c in
  (Shallow c', x)
pop_front' γ (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ} as d)) =
  if Chunk.empty fₒ then
    if ¬ (Chunk.empty fᵢ) then
      pop_front' γ (mk_deep' γ {d with fₒ=fᵢ, fᵢ=[⋮⋮]})
    else if ¬ (empty m) then 
      let (m', c) = pop_front' Chunk.weight m in
      pop_front' γ (mk_deep' γ {d with fₒ=c, m=m'})
    else if ¬ (Chunk.empty bᵢ) then
      pop_front' γ (mk_deep' γ {d with fₒ=bᵢ, bᵢ=[⋮⋮]})
    else
      let (bₒ', x) = Chunk.pop_front γ bₒ in
      (mk_deep' γ {d with bₒ=bₒ'}, x)
  else
    let (fₒ', x) = Chunk.pop_front γ fₒ in
    (mk_deep' γ {d with fₒ=fₒ'}, x)
~~~~~

Concatenation
-------------

~~~~~ {.ocaml}
push_buffer_back : α chunk wf → α chunk chunkedseq ✕ α chunk → α chunk chunkedseq
push_buffer_back γ (s, c)  =
  if Chunk.empty c then
    s
  else if empty s then
    Shallow (Chunk.push_back γ ([⋮⋮], c))
  else
    let (cs', c') = pop_back' γ cs in
    if Chunk.size c + Chunk.size c' ≤ Chunk.k then
      push_back' γ (cs', Chunk.concat γ (c', c))
    else
      push_back' γ (cs, c)
~~~~~

~~~~~ {.ocaml}
transfer_contents_back : α wf → α chunkedseq ✕ α chunk → α chunkedseq
  if Chunk.empty c then
    cs
  else
    let (c', x) = Chunk.pop_front γ c in
    transfer_contents_back γ (push_back' γ (cs, x), c')
~~~~~

~~~~~ {.ocaml}
concat' : α wf → α chunkedseq ✕ α chunkedseq → α chunkedseq
concat' γ (Shallow c₁, s₂) =
  transfer_contents_front γ (s₂, c₁)
concat' γ (s₁, Shallow c₂) =
  transfer_contents_back γ (s₁, c₂)
concat' γ (s₁ as Deep (_, {fₒ=fₒ₁, fᵢ=fᵢ₁, m=m₁, bᵢ=bᵢ₁, bₒ=bₒ₁}),
           s₂ as Deep (_, {fₒ=fₒ₂, fᵢ=fᵢ₂, m=m₂, bᵢ=bᵢ₂, bₒ=bₒ₂})) =
  let m₁' = push_buffer_back Chunk.weight (m₁, bᵢ₁) in
  let m₁'' = push_buffer_back Chunk.weight (m₁', bₒ₁) in
  let m₂' = push_buffer_front Chunk.weight (m₂, fᵢ₂) in
  let m₂'' = push_buffer_front Chunk.weight (m₂', fₒ₂) in
  let (m₁''', m₂''') =
    if empty m₁'' ∨ empty m₂'' then
      (m₁'', m₂'')
    else
      let (m₁''', c₁) = pop_back' Chunk.weight m₁'' in
      let (m₂''', c₂) = pop_front' Chunk.weight m₂'' in
      if Chunk.weight c₁ + Chunk.weight c₂ ≤ K then
        let c' = Chunk.concat γ (c₁, c₂) in
        (push_back' Chunk.weight (m₁''', c'), m₂''')
      else
        (m₁'', m₂'')
  let m₁₂ = concat' Chunk.weight (m₁''', m₂''') in
  mk_deep' γ {fₒ=fₒ₁, fᵢ=fᵢ₁, m=m₁₂, bᵢ=bᵢ₂, bₒ=bₒ₂}
~~~~~

Weighted split
--------------

~~~~~ {.ocaml}
split' : α wf → α chunkedseq ✕ int → (α chunkedseq ✕ α ✕ α chunkedseq)
split' γ (Shallow c, i) =
  let (c₁, x, c₂) = Chunk.split γ (c, i) in
  (Shallow c₁, x, Shallow c₂)
split' γ (Deep (_, {fₒ, fᵢ, m, bᵢ, bₒ} as d), i) =
  let (wfₒ, wfᵢ) = (Chunk.weight fₒ, Chunk.weight fᵢ) in
  let wₘ = weight m in
  let (wbᵢ, wbₒ) = (Chunk.weight bᵢ, Chunk.weight bₒ) in
  let (s₁, x, s₂) = 
    if i < wfₒ then
      let (fₒ₁, x, fₒ₂) = Chunk.split γ (fₒ, i) in
      let s₁ = mk_deep {fₒ=fₒ₁, fᵢ=[⋮⋮], m=Shallow [⋮⋮], bᵢ=[⋮⋮], bₒ=[⋮⋮]} in
      let s₂ = mk_deep {d with fₒ=fₒ₂} in
      (s₁, x, s₂)
    else if i < wfₒ + wfᵢ then
      let j = i - wfₒ in
      let (fᵢ₁, x, fᵢ₂) = Chunk.split γ (fᵢ, j) in
      let s₁ = mk_deep {d with fᵢ=[⋮⋮], m=Shallow [⋮⋮], bᵢ=[⋮⋮], bₒ=fᵢ₁} in
      let s₂ = mk_deep {d with fₒ=fᵢ₂, fᵢ=[⋮⋮]} in
      (s₁, x, s₂)
    else if i < wfₒ + wfᵢ + wₘ then
      let j = i - wfₒ - wfᵢ in
      let (m₁, c, m₂) = split' Chunk.weight (m, j) in
      let (c₁, x, c₂) = Chunk.split γ (c, j - weight m₁) in
      let s₁ = mk_deep {d with m=m₁, bᵢ=[⋮⋮], bₒ=c₁} in
      let s₂ = mk_deep {d with fₒ=c₂, fᵢ=[⋮⋮], m=m₂} in
      (s₁, x, s₂)
    else if i < wfₒ + wfᵢ + wₘ + wbᵢ then
      let j = i - wfₒ - wfᵢ - wₘ in
      let (bᵢ₁, x, bᵢ₂) = Chunk.split γ (bᵢ, j) in
      let s₁ = mk_deep {d with bᵢ=[⋮⋮], bₒ=bᵢ₁} in
      let s₂ = mk_deep {d with fₒ=bᵢ₂, fᵢ=[⋮⋮], m=Shallow [⋮⋮], bᵢ=[⋮⋮]} in
      (s₁, x, s₂)
    else
      let j = i - wfₒ - wfᵢ - wₘ - wbᵢ in
      let (bₒ₁, x, bₒ₂) = Chunk.split γ (bₒ, j) in
      let s₁ = mk_deep {d with bₒ=bₒ₁} in
      let s₂ = mk_deep {fₒ=bₒ₂, fᵢ=[⋮⋮], m=Shallow [⋮⋮], bᵢ=[⋮⋮], bₒ=[⋮⋮]} in
      (s₁, x, s₂)
  in
  (check γ s₁, x, check γ s₂)
~~~~~

Summary
=======

~~~~~ {.ocaml}
sub xs = ...

size xs = weight xs

back xs = ...

front xs = ...

push_front = push_front' γ₀
push_back = push_back' γ₀
...
split = split' γ₀
~~~~~

References
==========

Get the [bibtex file](chunkedseq.bib) used to generate these
references.

[^1]: [@chunkedseq14-esa]

[^2]: [@finger-trees]