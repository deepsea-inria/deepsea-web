
open Printf

(****************************************************************************)

let chunk_size = 256

type 'a t = 
  | SChain of { mutable head_nb : int;
                mutable head_data : 'a array;
                mutable back_nb : int;
                mutable back_data : ('a array) list; }
  | STable of { mutable table_nb : int;
                mutable table_data : 'a array; }
  | S0
  | S1 of 'a
  | S2 of 'a * 'a
  | S3 of 'a * 'a * 'a
  | S4 of 'a * 'a * 'a * 'a

let overhead_table = 4 (* 3+1 *)
let overhead_chain = 9 (* 5+3+1 *)

let empty = S0


let push x s =
  match s with 
(*   | SChain ({ head_nb = n; head_data = t; back_nb = nback; back_data = lback } as r) ->
      let m = Array.length t in
      if n < m then begin
        t.(n) <- x;
        r.head_nb <- n + 1; 
        s
*)
   | SChain r ->
      let m = Array.length r.head_data in
      let n = r.head_nb in
      if n < m then begin
        r.head_data.(n) <- x;
        r.head_nb <- n + 1; 
        s
      end else begin
        let nback = r.back_nb in      
        let lback = r.back_data in
        let t = r.head_data in

        let new_m = 
          if m < chunk_size 
            then min (2*m - 4) chunk_size 
            else chunk_size in
        assert (5 + (3+1) * (1+ List.length lback) + 1 + (n + nback) + new_m <= 2 * (n+nback+1));
         printf "resize to chain %d\n" new_m;
        (* printf "resize to chain %d\n" new_m; *)
        r.head_nb <- 1;
        r.head_data <- Array.make new_m x;
        r.back_nb <- n + nback;
        r.back_data <- t::lback;
        s
      end
 | STable ({ table_nb = n; table_data = t } as r) ->
      assert (n >= 5);
      let m = Array.length t in
      if n < m then begin
        t.(n) <- x;
        r.table_nb <- n + 1; 
        s
      end else if m < 18 then begin
        (* m values: 6, 2*7-4=10, 2*11-4=18 *)
        let new_n = n + 1 in
        let new_m = (2 * new_n) - overhead_table in
        (* printf "resize table to %d\n" new_m; *)
        assert (new_m > new_n);
        let new_t = Array.make new_m x in
        (* implicit: new_t.(n) <- x *)
        Array.blit t 0 new_t 0 n;
        r.table_data <- new_t;
        r.table_nb <- new_n; 
        s
      end else begin  
        let new_m = 10 in
        assert (n = 18);
        assert (5 + (3+1) + 1 + n + new_m = 2 * (n+1));
        (* new_n=19, 19*2-(9+18)=11 -> head_data.length=10 *)
        SChain { head_nb = 1;
                 head_data = Array.make new_m x;
                 back_nb = n;
                 back_data = [t]; }
      end
  | S0 -> S1 x
  | S1 (x1) -> S2 (x1,x)
  | S2 (x1,x2) -> S3 (x1,x2,x)
  | S3 (x1,x2,x3) -> S4 (x1,x2,x3,x)
  | S4 (x1,x2,x3,x4) -> 
      STable { table_nb = 5;
               table_data = [|x1;x2;x3;x4;x;x|] }
 



(****************************************************************************)


open Shared
exception Unsupported

module UnsupportedBackFront =
struct
   let back = (fun _ -> raise Unsupported)
   let front = (fun _ -> raise Unsupported)
end

module UnsupportedExtra =
struct
   let is_empty = (fun _ -> raise Unsupported)
   let length = (fun _ -> raise Unsupported)
   let transfer_to_back = (fun _ _ -> raise Unsupported)
   let carve_back_at = (fun _ _ -> raise Unsupported)
   let iter = (fun _ _ -> raise Unsupported)
   let fold_left = (fun _ _ _ -> raise Unsupported)
   let fold_right = (fun _ _ _ -> raise Unsupported)
   include UnsupportedBackFront
end

module UnsupportedSingleEnded =
struct
   let push_front = (fun _ _ -> raise Unsupported)
   let pop_front = (fun _ -> raise Unsupported)
end

module ChunkStackArray (Capacity : CapacitySig.S) =
struct
   include UnsupportedSingleEnded
   include UnsupportedExtra
   include StackArray
   let create d = make Capacity.capacity d
end

module StackMiddle = SeqSig.SeqOfPSeq(PList)
module Capacity = struct let capacity = chunk_size end
module Chunk = ChunkStackArray(Capacity)
module ChunkedStack = ChunkedStack.Make(Capacity)(Chunk)(StackMiddle)


(****************************************************************************)

type 'a u = UO | UN of 'a ChunkedStack.t

let empty' = UO

let push' x s =
  match s with
  | UO -> 
      let r = ChunkedStack.create 0 in
      ChunkedStack.push_back x r;
      UN r
  | UN r ->
      ChunkedStack.push_back x r;
      s

let length' s =
  match s with
  | UO -> 0
  | UN r -> ChunkedStack.length r


(****************************************************************************)

(* OK
type 'a chunk = 'a Chunk.t

type 'a r = { mutable whead : 'a chunk;
              mutable wback : ('a chunk) list; }

type 'a w = W0 | WN of 'a r

let empty'' = W0

let push'' x s =
  match s with
  | W0 -> 
      let t = Chunk.create 0 in
      Chunk.push_back x t;
      WN { whead = t ; wback = [] }
  | WN r -> 
    let t = r.whead in
    if Chunk.length r.whead = chunk_size then begin
       r.whead <- Chunk.create 0;
       r.wback <- t :: r.wback;
    end;
    Chunk.push_back x r.whead;
    s
*)
(* alternative:
    if Chunk.length t < chunk_size then begin
        Chunk.push_back x t;
        s
      end else begin
        let t2 = Chunk.create 0 in
        Chunk.push_back x t2;
        r.whead <- t2;
        r.wback <- t :: r.wback;
        s
      end
*)



(****************************************************************************)
(* OK


type 'a chunk = 'a Chunk.t


type 'a w = W0 | WN of { mutable whead_data : 'a array;
              mutable whead_nb : int;
              mutable wback : ('a array) list; 
              mutable wback_nb : int }
  | W1 of 'a
  | W2 of 'a * 'a
  | W3 of 'a * 'a * 'a
  | W4 of 'a * 'a * 'a * 'a

let empty'' = W0

let push'' x s =
  match s with
  | WN r -> 
    let m = Array.length r.whead_data in
    if r.whead_nb = m then begin
       r.wback <- r.whead_data :: r.wback;
       r.wback_nb <- r.whead_nb + r.wback_nb;
       let new_m = 
          if m = 6 then 18 
          else if m < chunk_size then min (2*m - 4) chunk_size 
          else chunk_size
          in
       r.whead_data <- Array.make new_m 0;
       r.whead_nb <- 0;
    end;
    let n = r.whead_nb in
    r.whead_data.(n) <- x;
    r.whead_nb <- n + 1;
    s
  | W0 -> W1 x
  | W1 (x1) -> W2 (x1,x)
  | W2 (x1,x2) -> W3 (x1,x2,x)
  | W3 (x1,x2,x3) -> W4 (x1,x2,x3,x)
  | W4 (x1,x2,x3,x4) -> WN { whead_data = [|x1;x2;x3;x4;x;x|] ; 
                             whead_nb = 5;
                             wback = [];
                             wback_nb = 0; }

*)


(****************************************************************************)


(**

Goal: (1+r)n be the maximum space usage to store n items.

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

type 'a chunk = 'a Chunk.t

type 'a w = W0  (* overhead = 0 *)
  | WChain of { mutable whead_data : 'a array;
              mutable whead_nb : int;
              mutable wback : ('a array) list; 
              mutable wback_nb : int }
    (* overhead = 6 + 4 * length wback + nb empty slots in head buffer *)
  | W1 of 'a  (* overhead = 1 *)
  | W2 of 'a * 'a (* idem .. *)
  | W3 of 'a * 'a * 'a
  | W4 of 'a * 'a * 'a * 'a
  | WTable of { mutable wtable_nb : int;
                mutable wtable_data : 'a array; }
          (* overhead = 4 *)        

 

let empty'' = W0

let push'' x s =
  match s with
  (* | W0 -> 
      let t = Array.make chunk_size x in
      WN { whead_data = t ; whead_nb = 1; wback = [] }
      *)
  | WChain r -> 
    let m = Array.length r.whead_data in
    if r.whead_nb = m then begin
       r.wback <- r.whead_data :: r.wback;
       r.wback_nb <- r.whead_nb + r.wback_nb;
       let new_m = 
          if m = 6 then (*10
          else if m = 10 then *) 18 
          else if m < chunk_size then min (2*m - 4) chunk_size 
          else chunk_size
          in
       r.whead_data <- Array.make new_m 0;
       r.whead_nb <- 0;
    end;
    let n = r.whead_nb in
    r.whead_data.(n) <- x;
    r.whead_nb <- n + 1;
    s
  | W0 -> W1 x
  | W1 (x1) -> W2 (x1,x)
  | W2 (x1,x2) -> W3 (x1,x2,x)
  | W3 (x1,x2,x3) -> W4 (x1,x2,x3,x)
  | W4 (x1,x2,x3,x4) -> WTable { wtable_data = [|x1;x2;x3;x4;x;x|] ; 
                                 wtable_nb = 5 }
  | WTable ({ wtable_nb = n; wtable_data = t } as r) ->
      assert (n >= 5);
      let m = Array.length t in
      if n < m then begin
        t.(n) <- x;
        r.wtable_nb <- n + 1; 
        s
      end else if m < 18 then begin
        (* m values: 6, 2*7-4=10, 2*11-4=18 *)
        let new_n = n + 1 in
        let new_m = (2 * new_n) - overhead_table in
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
        WChain { whead_nb = 1;
                 whead_data = Array.make new_m x;
                 wback_nb = n;
                 wback = [t]; }
      end



(****************************************************************************)
  
let measured_run f =
   begin try
      let t1 = Sys.time() in 
      f();
      let t2 = Sys.time() in
      printf "exectime %.2f\n" (t2 -. t1);
   with Unsupported -> printf "exectime NA (unsupported)\n" 
   end

type distrib_mode = ModeRoundRobin | ModeRandom

let test_func seq distrib_mode nb_buckets nb_items () =
  let next_item () = 
    1 in
  let b = ref 0 in
  let next_bucket () =
    match distrib_mode with
    | ModeRoundRobin -> 
        let i = !b in 
        incr b; 
        if !b = nb_buckets
          then b := 0;
        i
    | ModeRandom -> Random.int nb_buckets
    in

  if seq = "list" then begin

    let t = Array.make nb_buckets [] in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- next_item() :: t.(b);
    done

  end else if seq = "old_packed" then begin

    let t = Array.make nb_buckets empty in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- push (next_item()) t.(b);
    done

  end else if seq = "chunked_stack" then begin

    let t = Array.make nb_buckets (ChunkedStack.create 0) in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      ChunkedStack.push_back (next_item()) t.(b)
    done

   end else if seq = "wrap_chunked_stack" then begin

    let t = Array.make nb_buckets empty' in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- push' (next_item()) t.(b)
    done;
    if nb_buckets = 1 then assert (length' t.(0) = nb_items);

   end else if seq = "packed" then begin

    let t = Array.make nb_buckets empty'' in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- push'' (next_item()) t.(b)
    done

   end else if seq = "stack_array" then begin

    let t = Array.make nb_buckets (StackArray.make 3000000 0) in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      (* t.(b) <- push (next_item()) t.(b); *)
      StackArray.push_back (next_item()) t.(b)
    done

   end else if seq = "stack_array_direct" then begin

    let t = StackArray.make nb_items 0 in
    for i = 0 to nb_items - 1 do
      StackArray.push_back (next_item()) t
   done

   end else if seq = "chunked_stack_direct" then begin

    let t = ChunkedStack.create 0 in
    for i = 0 to nb_items - 1 do
      ChunkedStack.push_back (next_item()) t
   done

   end else if seq = "packed_direct" then begin

    let t = ref empty'' in
    for i = 0 to nb_items - 1 do
      t := push'' (next_item()) !t
   done



  end

let _ =
   let seq = Cmdline.parse_or_default_string "seq" "list" in 
   let distrib_mode = 
      match Cmdline.parse_or_default_string "distrib_mode" "round_robin" with
      | "round_robin" -> ModeRoundRobin 
      | "random" -> ModeRandom
      | _ -> failwith "invalid distrib_mode"
      in
   let nb_buckets = Cmdline.parse_or_default_int "nb_buckets" 10000000 in 
   let nb_items = Cmdline.parse_or_default_int "nb_items" 30000000 in 
   measured_run (test_func seq distrib_mode nb_buckets nb_items)





(****************************************************************************)

(*
type 'a v = VO | VN of { mutable data : 'a ChunkedStack.t; mutable n : int }
  | V1 of 'a
  | V2 of 'a * 'a
  | V3 of 'a * 'a * 'a
  | V4 of 'a * 'a * 'a * 'a

let empty'' = VO

let push'' x s =
  match s with
  | VO -> 
      let t = ChunkedStack.create 0 in
      ChunkedStack.push_back x t;
      VN { data = t ; n = 1 }
  | VN ({ data = t ; n = n } as r) ->
      ChunkedStack.push_back x t;
      r.data <- t;
      r.n <- r.n + 1;
      s
  | V1 (x1) -> V2 (x1,x)
  | V2 (x1,x2) -> V3 (x1,x2,x)
  | V3 (x1,x2,x3) -> V4 (x1,x2,x3,x)
  | V4 (x1,x2,x3,x4) -> assert false
*)


(****************************************************************************)

(*
type 'a chunk = 'a Chunk.t

type 'a w = W0 | WN of { mutable whead : 'a chunk;
                         mutable wback : ('a chunk) list; }

let empty'' = W0

let push'' x s =
  match s with
  | W0 -> 
      let t = Chunk.create 0 in
      Chunk.push_back x t;
      WN { whead = t ; wback = [] }
  | WN ({ whead = t ; wback = l } as r) ->
      if Chunk.length t < chunk_size then begin
        Chunk.push_back x t;
        s
      end else begin
        let t2 = Chunk.create 0 in
        Chunk.push_back x t2;
        r.whead <- t;
        r.wback <- t :: r.wback;
        s
      end
*)