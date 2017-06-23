
(****************************************************************************)

(**

This structure implements an imperative stack able to store n items
using at most (1+r)n words, for a small r, e.g. 1, or 2.

The ratio [r] could even be 0.5, if we're ready to add a couple more
constructors for base cases.

Note that this ratio applies to growing stacks. If "pop" operations is
also used, then there are two cases. If all items are pushed, then all
items are popped, the ratio for shrinking the capacity may be the same
as that for growing the capacity. Otherwise, one needs a different ratio
for "pop", leading to more waisted space.


A sequence of length n is in direct representation (single constructor)
as long as   n * r <= 4.

Slightly longer sequences are represented in an array, of size T with:
  T <= n*(1+r)-4

When the array is full, it is realloacted with a capacity of
  n*(1+r)-4, where n is the number of elements after the push operation
that made the prior array overflow.

This resizing continues as long as the following inequality is true:
  r*r*n <= 10*r+4
  (reason is, the first buffer will have size x=r*n-10,
   and we want this buffer to pay for more than its overhead,
   i.e. r*x>4, to allow buffer size to increase).

When the above inequality becomes false, we switch to a linked list of chunks.
The size of the first chunk, pushing 1 element onto a sequence of n elements,
is given by:
  k = r*(n+1) - 9
  (this comes from (1+r)*(n+1)-10-n).

After that, the size of chunks keeps increasing; If k denotes the previous
chunk size and k' denotes the next chunk size,
  k' = min(256, (1+r)*k-4)
  (assuming above 256 to be the ideal chunk size)
  (reason is, the last buffer added 4 words of overheads, for (1+r)*k credits,
  so the difference (1+r)k-4 describes the number of additional free slots 
  allowed to be allocated in the next chunk).

Code below is specialized for r=1

*)

open Printf

module Make (Capacity : CapacitySig.S) 
= struct

(*--------------------------------------------------------------------------*)

let capacity = Capacity.capacity

type 'a t =
  (* long sequences 
     overhead = 6 words + 4 * length wback + nb empty slots in head buffer *)
  | SChain of { mutable whead_data : 'a array;
                mutable whead_nb : int;
                mutable wback : ('a array) list; 
                mutable wback_nb : int }
  (* empty sequence, overhead = 0 word *)
  | S0
  (* very short sequences, overhead = 1 word *)
  | S1 of 'a
  | S2 of 'a * 'a
  | S3 of 'a * 'a * 'a
  | S4 of 'a * 'a * 'a * 'a
  (* short sequences, overhead = 4 words *)
  | STable of { mutable wtable_nb : int;
                mutable wtable_data : 'a array; }
          (* overhead = 4 *)        

let empty = S0

let push_back x s =
  match s with
  | SChain r -> 
    let m = Array.length r.whead_data in
    if r.whead_nb = m then begin
       r.wback <- r.whead_data :: r.wback;
       r.wback_nb <- r.whead_nb + r.wback_nb;
       let new_m = min (2*m - 4) capacity in
       (* printf "chain next alloc %d\n" new_m; *)
          (* equivalent to:
          let new_m = if m < capacity 
            then min (2*m - 4) capacity 
            else capacity *)
       let default = x in (* TODO *)
       r.whead_data <- Array.make new_m default;
       r.whead_nb <- 0;
    end;
    let n = r.whead_nb in
    r.whead_data.(n) <- x;
    r.whead_nb <- n + 1;
    s
  | S0 -> S1 x
  | S1 (x1) -> S2 (x1,x)
  | S2 (x1,x2) -> S3 (x1,x2,x)
  | S3 (x1,x2,x3) -> S4 (x1,x2,x3,x)
  | S4 (x1,x2,x3,x4) -> 
      (* printf "first table size is %d\n" 6; *)
      STable { wtable_data = [|x1;x2;x3;x4;x;x|] ; 
                                 wtable_nb = 5 }
  | STable ({ wtable_nb = n; wtable_data = t } as r) ->
      assert (n >= 5);
      let m = Array.length t in
      if n < m then begin
        t.(n) <- x;
        r.wtable_nb <- n + 1; 
        s
      end else if m < 18 then begin
        (* m values: 6, 2*7-4=10, 2*11-4=18 *)
        let new_n = n + 1 in
        let new_m = (2 * new_n) - 4 in (* 4 is overhead of table *)
        (* printf "resize table to %d\n" new_m; *)
        assert (new_m > new_n);
        let new_t = Array.make new_m x in
        (* implicit: new_t.(n) <- x *)
        Array.blit t 0 new_t 0 n;
        r.wtable_data <- new_t;
        r.wtable_nb <- new_n; 
        s
      end else begin  
        let new_m = 10 in
        assert (n = 18);
        assert (5 + (3+1) + 1 + n + new_m = 2 * (n+1));
        (* new_n=19, overheads_so_far=9, items_so_far=181
           the allowed space is: 19*2-(9+18)=11,
           since there is one word for the array header,
           we may afford to take head_data.length=10 *)
        (* printf "chunk first alloc %d\n" new_m; *)
        SChain { whead_nb = 1;
                 whead_data = Array.make new_m x;
                 wback_nb = n;
                 wback = [t]; }
      end

let pop_back s =
  match s with
  | SChain r -> 
    let n = r.whead_nb in
    (* assert (n >= 1); TODO: revive this *)
    let new_n = n-1 in
    let x = r.whead_data.(new_n) in
    if new_n = 0 then begin
      (* TODO: implement change of constructor *)
      match r.wback with
      | [] -> () (* TODO: should be dead branch *)
      | t::q -> 
          let new_n' = Array.length t in
          r.whead_data <- t;
          r.whead_nb <- new_n';
          r.wback <- q;
          r.wback_nb <- r.wback_nb - new_n';
    end else begin
      r.whead_nb <- new_n;
    end;
    x, s  
  | S0 -> raise Not_found
  | S1 (x1) -> x1, S0
  | S2 (x1,x2) -> x2, S1 (x1)
  | S3 (x1,x2,x3) -> x3, S2 (x1,x2)
  | S4 (x1,x2,x3,x4) -> x4, S3 (x1,x2,x3)
  | STable ({ wtable_nb = n; wtable_data = t } as r) ->
      assert (n >= 5);
      if n = 5 then begin 
         t.(4), S4 (t.(0), t.(1), t.(2), t.(3))
      end else 
      let _m = Array.length t in
      (* TODO: implement table capacity decrease correctly *)
      let new_n = n-1 in
      let x = t.(new_n) in
      r.wtable_nb <- new_n; 
      x, s

let split_at i s = assert false
let append s1 s2 = assert false

let to_list s = 
  match s with
  | SChain r ->
      List.concat (List.rev (List.map (fun c -> Array.to_list c) r.wback))
    @ Array.to_list (Array.sub r.whead_data 0 r.whead_nb)
  | S0 -> []
  | S1 (x1) -> [x1]
  | S2 (x1,x2) -> [x1;x2]
  | S3 (x1,x2,x3) -> [x1;x2;x3]
  | S4 (x1,x2,x3,x4) -> [x1;x2;x3;x4] 
  | STable { wtable_nb = n; wtable_data = t } ->
      Array.to_list (Array.sub t 0 n)


end