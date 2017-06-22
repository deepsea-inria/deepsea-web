
(****************************************************************************)

(**

This structure implements an imperative stack able to store n items
using at most (1+r)n words, for a small r, e.g. 1, or 2.

The ratio [r] could even be 0.5, if we're ready to add a couple more
constructors for base cases.

A sequence of length n is in direct representation (single constructor)
while  n * r <= 4.

After that, it is represented in an array, of size T with.
  T <= n*(1+r)-4

When the array is full, it is grown to the maximal value of
  n*(1+r)-4, where n is the number of elements after the push operation.

This resizing continues as long as the following inequality is true.
  r*r*n <= 10*r+4
  (reason is, the first buffer will have size x=r*n-10,
   and we want this buffer to pay for more than its overhead,
   i.e. r*x>4, to allow buffer size to increase).

When the inequality becomes false, we switch to a linked list of chunks.
The size of the first chunk, pushing 1 element onto a sequence of n elements,
is given by:
  r*(n+1) - 9
  (this comes from (1+r)*(n+1)-10-n).

After that, the size of chunks increases as follows:
  k' = (1+r)*k - 4
  (reason is, the last buffer added 4 overheads, for (1+r)*k credits,
  so the difference describes the number of additional slots allowed).

*)

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
       let new_m = 
          if m = 6 then (*10
          else if m = 10 then *) 18 
          else if m < capacity then min (2*m - 4) capacity 
          else capacity
          in
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
  | S4 (x1,x2,x3,x4) -> STable { wtable_data = [|x1;x2;x3;x4;x;x|] ; 
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
        (* new_n=19, 19*2-(9+18)=11 -> head_data.length=10 *)
        SChain { whead_nb = 1;
                 whead_data = Array.make new_m x;
                 wback_nb = n;
                 wback = [t]; }
      end

let pop_back s =
  match s with
  | SChain r -> 
    let m = Array.length r.whead_data in
    assert (m >= 1);
    let n = r.whead_nb in
    let new_n = n-1 in
    let x = r.whead_data.(new_n) in
    if new_n = 0 then begin
      (* TODO: implement change of constructor *)
      match r.wback with
      | [] -> raise Not_found
      | t::q -> 
          r.whead_data <- t;
          r.whead_nb <- capacity;
          r.wback <- q;
          r.wback_nb <- r.wback_nb - capacity;
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
let to_list s = assert false
let append s1 s2 = assert false

end