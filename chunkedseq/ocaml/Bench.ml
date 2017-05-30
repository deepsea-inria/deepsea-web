open Printf
open Shared

exception Unsupported


(****************************************************************************)

module type SeqSig = SeqSig.S
module type PSeqSig = PSeqSig.S

let size_for_static_array = Cmdline.parse_or_default_int "static_array_size" 20000000
  (* enough to fit all items from experiments *)

let chunk_size = (Cmdline.parse_or_default_int "chunk" 256) 
  (* use 3 for debugging *)

module Capacity : CapacitySig.S = struct let capacity = chunk_size end

module Capacity16 : CapacitySig.S = struct let capacity = 16 end

module Capacity256 : CapacitySig.S = struct let capacity = 256 end

module Chunk : SeqSig = CircularArray.Make(Capacity)

(* best for copy on write chunks *)
module Chunk16 : SeqSig = CircularArray.Make(Capacity16)

(* best for ephemeral stack; 128 is ok too *)
module Chunk256 : SeqSig = CircularArray.Make(Capacity256)

module Middle : SeqSig  = CircularArray.Make(
  struct let capacity = 1 + size_for_static_array / chunk_size end)
  (* TODO: change this *)

module PMiddle : PSeqSig = PChunkedSeq


(****************************************************************************)

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


(****************************************************************************)

(** OCaml Array *)

module TestSizedArray =
struct
   type 'a t = {
      data : 'a array;
      mutable size : int; }
   let create_capacity nb d = {
      data = Array.make nb d;
      size = 0 }
   let create d = {
      data = Array.make size_for_static_array d;
      size = 0 }
   let push_back x s = 
      let n = s.size in
      s.data.(n) <- x;
      s.size <- n + 1
   let pop_back s = 
      let n = s.size - 1 in
      let x = s.data.(n) in
      s.size <- n;
      x
   let to_list s =
      let acc = ref [] in
      for i = s.size - 1 downto 0 do
        acc := s.data.(i) :: !acc;
      done;
      !acc
   include UnsupportedSingleEnded
   include UnsupportedExtra
end

(** OCaml Array of large capacity *)

module TestSizedArrayBig : SeqSig =
struct
   type 'a t = {
      data : 'a array;
      mutable size : int; }
   let create d = {
      data = Array.make size_for_static_array d;
      size = 0 }
   let push_back x s = 
      let n = s.size in
      s.data.(n) <- x;
      s.size <- n + 1
   let pop_back s = 
      let n = s.size - 1 in
      let x = s.data.(n) in
      s.size <- n;
      x
   let to_list s =
      let acc = ref [] in
      for i = s.size - 1 downto 0 do
        acc := s.data.(i) :: !acc;
      done;
      !acc
   include UnsupportedSingleEnded
   include UnsupportedExtra
end

(** Vector *)

module TestVector : SeqSig =
struct
   type 'a t = 'a Vector.t
   let create = Vector.create
   let push_back = Vector.push_back
   let pop_back = Vector.pop_back
   let to_list = Vector.to_list
   include UnsupportedSingleEnded
   include UnsupportedExtra
end

(** Circular Array *)

module TestCircularArrayBig (* : SeqSig *) =
struct
   include CircularArray.Make 
      (struct let capacity = size_for_static_array end)
   include UnsupportedExtra
end

(** OCaml Queue *)

module TestOcamlQueue : SeqSig =
struct
   type 'a t = 'a Queue.t
   let create d = Queue.create ()
   let push_back x s = Queue.push x s
   let pop_front s = Queue.pop s
   let push_front x s = raise Unsupported
   let pop_back s = raise Unsupported
   let to_list s =
      List.rev (Queue.fold (fun acc x -> x::acc) [] s)
   include UnsupportedExtra
end

(** OCaml List *)

module TestOcamlList : SeqSig = SeqSig.SeqOfPSeq(struct
   type 'a t = 'a list
   let empty = 
      []
   let is_empty s =
      s = []
   let push_back x s = 
      x::s
   let length s =
      List.length s
   let pop_back = 
      (function | a::q -> (a,q) | _ -> failwith "Not_found in pop_front")
   let pop_front s = (* warning: linear-time, but no stack explosion *)
      (* todo: use a more clever technique *)
      let r = list_rev_notrec s in
      let (x,r') = pop_back r in
      (x, list_rev_notrec r)
   let append s1 s2 = (* warning: linear-time, but no stack explosion *)
      let t1 = ref (list_rev_notrec s1) in
      let t2 = ref s2 in
      while !t1 <> [] do
         let (x,q) = pop_front !t1 in
         t1 := q;
         t2 := x::!t2;
      done;
      !t2
   let push_front x s = (* warning: linear-time, but no stack explosion *)
      append s [x]
   let split_at i s = (* warning: linear-time, but no stack explosion *)
      let t = ref s in
      let r = ref [] in
      let k = ref i in
      while !k > 0 do
         let (x,q) = pop_front !t in
         t := q;
         r := x::!r;
         decr k;
      done;
      (list_rev_notrec !r, !t)
   let iter = List.iter
   let fold_left = List.fold_left
   let fold_right = List.fold_right
   let to_list s = 
      s
   include UnsupportedBackFront
end)

(** Sized List *)

module TestSizedList : SeqSig = SeqSig.SeqOfPSeq(
  SizedList)

(** Sized Two Lists *)

module TestSizedTwoLists : SeqSig = SeqSig.SeqOfPSeq(
  SizedTwoLists)

(** Persistant Chunk *)

module TestPArray : SeqSig = SeqSig.SeqOfPSeq(
  PArray)

(** Persistant Chunk *)

module TestPersistentChunk : SeqSig = SeqSig.SeqOfPSeq(
  PersistentChunk.Make(Capacity))

(** Ephemeral Chunked Stack *)

module TestChunkedStack : SeqSig = struct
  include ChunkedStack.Make(Capacity)(Chunk)(Middle)
  include UnsupportedBackFront
end

(** Ephemeral Chunked Stack with capacity 256 *)

module TestChunkedStack256 : SeqSig = struct
  include ChunkedStack.Make(Capacity256)(Chunk256)(Middle)
  include UnsupportedBackFront
end

   
(** Ephemeral Chunked Seq *)

(* TODO
module TestChunkedSeq : SeqSig = struct
  include ChunkedSeq.Make(Capacity)(Chunk)(Middle)
  include UnsupportedExtra
end
*)
   
(** Pure Chunked Seq *)

module TestPChunkedSeq : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedSeq)

(** Chunked Stack Copy on Write *)

module PChunkedStackCopyOnWrite : PSeqSig = 
  PChunkedStack.Make(Capacity)(PArray)(PMiddle)

module TestPChunkedStackCopyOnWrite : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackCopyOnWrite)

module PChunkedStackCopyOnWrite16 : PSeqSig = 
  PChunkedStack.Make(Capacity16)(PArray)(PMiddle)

module TestPChunkedStackCopyOnWrite16 : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackCopyOnWrite16)

(** Chunked Stack Persistence *)

module PChunkedStackPersistence : PSeqSig = 
  PChunkedStack.Make(Capacity)(PersistentChunk.Make(Capacity))(PMiddle)

module TestPChunkedStackPersistence : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackPersistence)

(** Chunked String with Persistence *)

module TestPChunkedString =
  PChunkedString.Make(Capacity)(PMiddle)
(* TODO: fix capacity once and forall *)


(****************************************************************************)

let debug = ((Cmdline.parse_or_default_int "debug" 0) <> 0)
let gc_major = ((Cmdline.parse_or_default_int "gc_major" 0) <> 0)
let def = 0


(* FOR DEBUG
let show_str r =
   fprintf stdout "==> %a\n" (Test_Boot_Seq.print (fun ppf x -> fprintf ppf "%d" x)) (Obj.magic r : Test_Boot_Seq.t)  
*)

module Scenari (Seq : SeqSig) =
struct

let show_list l =
   List.iter (fun x -> printf "%d " x) l;
   print_newline()

let show q =
   show_list (Seq.to_list q)


let fifo_debug_1 () () = 
   let q = Seq.create def in
   let a = ref 0 in
   let b = ref 0 in
   for i = 1 to 20 do
      Seq.push_back (!a) q;
      incr a;
      if debug then show q;
   done;
   for i = 1 to 20 do
      let x = Seq.pop_front q in
      if (x <> !b) then failwith (sprintf "expected %d, got %d\n" !b x);
      assert (x = !b);
      incr b;
      if debug then show q;
   done

let lifo_debug_1 () () = 
   let q = Seq.create def in
   let a = ref 0 in
   for i = 1 to 10 do
      Seq.push_back (!a) q;
      incr a;
      if debug then show q;
   done;
   for i = 1 to 10 do
      let x = Seq.pop_back q in
      decr a;
      if (x <> !a) then failwith (sprintf "expected %d, got %d\n" !a x);
      assert (x = !a);
      if debug then show q;
   done


(****************************************************************************)


(** Push 10k items, then repeat n times: push_back (n/r) items
    followed by pop_front (n/r) items. *)

let fifo_1 nbitems repeat () () =
   assert (repeat > 0);
   assert (nbitems >= 10000);
   let q = Seq.create def in
   let a = ref 0 in
   let b = ref 0 in
   for i = 1 to 10000 do
      Seq.push_back (!a) q;
      incr a;
   done;
   let nbitems = nbitems - 10000 in
   let block = nbitems / repeat in
   for j = 1 to repeat do
      for i = 1 to block do
         Seq.push_back (!a) q;
         incr a;
      done;
      for i = 1 to block do
         let x = Seq.pop_front q in
         assert (x = !b);
         incr b;
      done;
   done


(** Push 10k items, then repeat n times: push_back (n/r) items
    followed by pop_back (n/r) items. *)

let lifo_1 nbitems repeat () () = 
   assert (repeat > 0);
   assert (nbitems >= 10000);
   let q = Seq.create def in
   let a = ref 0 in
   for i = 1 to 10000 do
      Seq.push_back (!a) q;
      incr a;
   done;
   let nbitems = nbitems - 10000 in
   let block = nbitems / repeat in
   for j = 1 to repeat do
     for i = 1 to block do
        Seq.push_back (!a) q;
        incr a;
     done;
     if gc_major then Gc.major();
     for i = 1 to block do
        let x = Seq.pop_back q in
        decr a;
        assert (x = !a);
     done;
  done


(****************************************************************************)

(* TODO
  let split_debug_1 () () = 
     let q = Seq.create def in
     let a = ref 0 in
     for i = 1 to 20 do
        Seq.push_back (!a) q;
        incr a;
        if debug then show q;
     done;
     let check x y q =
        if debug then show q;
        let rec aux z l = 
           match l with
           | [] -> 
              if z <> y+1 then failwith "expected end of sequence"
           | v::l' -> 
              if v <> z then failwith (sprintf "expected %d, got %d\n" z v);
              aux (z+1) l'
           in
        aux x (Seq.to_list q)
        in
     let (q_0_9,q_10_19) = Seq.split_at 10 q in
     check 10 19 q_10_19;
     if debug then show q_0_9;
     let (q_0_4,q_5_9) = Seq.split_at 5 q_0_9 in
     check 0 4 q_0_4;
     if debug then show q_5_9;
     let (q_5_5,q_6_9) = Seq.split_at 1 q_5_9 in
     check 5 5 q_5_5;
     check 6 9 q_6_9;
     let (q_none,q_6_9') = Seq.split_at 0 q_6_9 in
     if Seq.to_list q_none <> [] then failwith "expected empty sequence";
     check 6 9 q_6_9';
     let (q_6_9'',q_none') = Seq.split_at 4 q_6_9' in
     if Seq.to_list q_none' <> [] then failwith "expected empty sequence";
     check 6 9 q_6_9''


  type side = Front | Back

  module SeqRef = TestOcamlList 
  let show_oli s = show_list (SeqRef.to_list s)

  (** Perform a sequence of merge operations both on Seq and on 
      OCaml list, and make sure the sequences remain consistent. *)

  let merge_debug_generic debug actions =
     let q = ref (Seq.create def) in
     let s = ref (SeqRef.create def) in
     let a = ref 0 in
     let run (nbitems,side) = 
        let q' = Seq.create def in
        let s' = SeqRef.create def in
        for i = 1 to nbitems do
           Seq.push_front !a q';
           SeqRef.push_front !a s';
           incr a;
        done;
        let report l1 l2 l1' l2' =
           if debug then begin
              printf "---merging two lists below:\n";
              show_oli l1;
              (* show_str l2; *)
              show_oli l1';
              (* show_str l2'; *)
           end
           in
        if side = Front then begin
           report !s !q s' q';
           q := Seq.append !q q';
           s := SeqRef.append !s s';
        end else begin
           report s' q' !s !q ;
           q := Seq.append q' !q;
           s := SeqRef.append s' !s;
        end;
        let l1 = Seq.to_list !q in
        let l2 = SeqRef.to_list !s in
        if debug then begin
           printf "result:\n";
           show_list l1;
           (* show_str !q; *)
        end;
        if l1 <> l2 then begin
           show_list l1; 
           show_list l2;
           failwith "sequences differs"
        end
        in
      List.iter run actions

  let merge_debug_1 () () =
     let actions = [ (0, Front); (5, Front); (8, Back); (2, Front); (5, Back); (25, Back); (20, Front) ] in
     merge_debug_generic debug actions

  let merge_debug_2 nb_actions max_items_per_action () () =
     let actions = list_init nb_actions (fun i ->
        let k = Random.int (2 * max_items_per_action) in
        let nb = k / 2 in
        let side = if k mod 2 = 0 then Front else Back in
        (nb, side)) in
     let debug = false in
     merge_debug_generic debug actions

  (** Fill in b buckets, with a total of n items, and repeat r times: 
     pick two buckets at random, merge them, then pick two buckets at
     random, split them at a random position. *)

  let split_merge_1 n_items r_ops b_buckets () =
     assert (b_buckets >= 2);
     let random_values = Array.init (5*r_ops) (fun _ -> Random.int 1000000) in
     let random_index = ref (-1) in
     let rand () = 
        incr random_index;
        random_values.(!random_index)
        in
     let items_per_bucket = n_items / b_buckets in
     let a = ref 0 in
     let buckets = Array.init b_buckets (fun _ -> 
        let s = Seq.create def in
        for i = 1 to items_per_bucket do
           Seq.push_back !a s;
           incr a;
        done;
        s) in
     fun () -> begin
        for i = 1 to r_ops do
           let a = rand() mod b_buckets in
           let b = rand() mod (b_buckets-1) in
           let b = if b < a then b else b+1 in
           buckets.(a) <- Seq.append buckets.(a) buckets.(b);
           let c = rand() mod (b_buckets-1) in
           let c = if c < b then c else c+1 in
           let s = buckets.(c) in
           let n = Seq.length s in
           let pos = (rand()) mod (n+1) in
           let (u,v) = Seq.split_at pos s in
           buckets.(b) <- u;
           buckets.(c) <- v;   
        done
     end
*)

end



(****************************************************************************)

(* todo: test get expected number ! *)

let real_lifo seq nbitems repeat () () = 
   begin
   assert (repeat > 0);
   let block = nbitems / repeat in
   printf "length %d\n" block;
   if seq = "ocaml_list" then begin

      let r = ref [] in
      for j = 1 to repeat do
        for i = 1 to block do
           r := 1::!r;
        done;
        for i = 1 to block do
           match !r with
           | [] -> assert false
           | x::t -> r := t
        done;
     done

   end else if seq = "pchunked_seq" then begin

      let r = ref PChunkedSeq.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := PChunkedSeq.push_back 1 !r;
        done;
        for i = 1 to block do 
           let (x,t) = PChunkedSeq.pop_back !r in
           r := t
        done;
     done

   end else if seq = "pchunked_stack_copy_on_write_16" then begin

      let r = ref PChunkedStackCopyOnWrite16.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := PChunkedStackCopyOnWrite16.push_back 1 !r;
        done;
        for i = 1 to block do 
           let (x,t) = PChunkedStackCopyOnWrite16.pop_back !r in
           r := t
        done;
     done

   end else if seq = "pchunked_stack_copy_on_write" then begin

      let r = ref PChunkedStackCopyOnWrite.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := PChunkedStackCopyOnWrite.push_back 1 !r;
        done;
        for i = 1 to block do 
           let (x,t) = PChunkedStackCopyOnWrite.pop_back !r in
           r := t
        done;
     done

   end else if seq = "pchunked_stack_persistence" then begin

      let r = ref PChunkedStackPersistence.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := PChunkedStackPersistence.push_back 1 !r;
        done;
        for i = 1 to block do 
           let (x,t) = PChunkedStackPersistence.pop_back !r in
           r := t
        done;
     done

   end else if seq = "chunked_stack" then begin

      let r = TestChunkedStack.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestChunkedStack.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestChunkedStack.pop_back r in
           ()
        done;
     done

   end else if seq = "chunked_stack_256" then begin

      let r = TestChunkedStack256.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestChunkedStack256.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestChunkedStack256.pop_back r in
           ()
        done;
     done

   end else if seq = "vector" then begin

      let r = TestVector.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestVector.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestVector.pop_back r in
           ()
        done;
     done

   end else if seq = "circular_array_big" then begin

      let r = TestCircularArrayBig.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestCircularArrayBig.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestCircularArrayBig.pop_back r in
           ()
        done;
     done

   end else if seq = "sized_array_big" then begin

      let r = TestSizedArrayBig.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestSizedArrayBig.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestSizedArrayBig.pop_back r in
           ()
        done;
     done

   end else if seq = "sized_array" then begin

      let r = TestSizedArray.create_capacity block def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestSizedArray.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestSizedArray.pop_back r in
           ()
        done;
     done

   end else failwith "unsupported seq for scenario real_lifo"
  end
  

let real_fifo seq nbitems repeat () () =
   assert (repeat > 0);
   let block = nbitems / repeat in
   printf "length %d\n" block;
   if seq = "circular_array_big" then begin

      let r = TestCircularArrayBig.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestCircularArrayBig.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestCircularArrayBig.pop_front r in
           ()
        done;
     done

   end else if seq = "ocaml_queue" then begin

      let r = TestOcamlQueue.create def in
      for j = 1 to repeat do
        for i = 1 to block do
           TestOcamlQueue.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = TestOcamlQueue.pop_front r in
           ()
        done;
     done

   end else failwith "unsupported seq for scenario real_fifo"


let real_string_buffer seq nbitems length () () = 
  let max_word_size = length in
  let words = Array.init max_word_size (fun i ->
     Bytes.make i 'x') in
  let nb = ref 0 in
  let next_word () =
     let k = Random.int max_word_size in
     let w = words.(k) in
     nb := !nb + k;
     w in

  if seq = "ocaml_buffer" then begin

      let s = Buffer.create 0 in
      while !nb < nbitems do
        let w = next_word() in
        Buffer.add_bytes s w;
      done

  end else if seq = "pchunked_string" then begin

      let r = ref TestPChunkedString.empty in
      while !nb < nbitems do
        let w = next_word() in
        r := TestPChunkedString.add_bytes w !r;
      done

   end else failwith "unsupported seq for scenario real_string_buffer"


(* TODO: a string_buffer_debug function *)


(****************************************************************************)

let measured_run f =
   begin try
      let t1 = Sys.time() in 
      f();
      let t2 = Sys.time() in
      printf "exectime %.2f\n" (t2 -. t1);
   with Unsupported -> printf "exectime NA (unsupported)\n" 
   end

let select choices key =
   try List.assoc key choices
   with Not_found -> failwith (sprintf "not a valid choice: %s\n" key)

let _ =
   let testname = Cmdline.parse_or_default_string "test" "all" in
   let seq = Cmdline.parse_string "seq" in
   let seq_module = 
      if seq = "sized_array" then (module TestSizedArray : SeqSig)
      else if seq = "sized_array_big" then (module TestSizedArrayBig : SeqSig)
      else if seq = "vector" then (module TestVector : SeqSig)
      else if seq = "circular_array_big" then (module TestCircularArrayBig : SeqSig) 
      else if seq = "ocaml_queue" then (module TestOcamlQueue : SeqSig)
      else if seq = "ocaml_list" then (module TestOcamlList : SeqSig)
      else if seq = "sized_list" then (module TestSizedList : SeqSig)
      else if seq = "sized_two_lists" then (module TestSizedTwoLists : SeqSig)
      else if seq = "parray" then (module TestPArray : SeqSig)
      else if seq = "persistent_chunk" then (module TestPersistentChunk : SeqSig)
      else if seq = "chunked_stack" then (module TestChunkedStack : SeqSig)
      else if seq = "chunked_stack_256" then (module TestChunkedStack256 : SeqSig)
      (* TODO
      else if seq = "chunked_seq" then (module TestChunkedSeq : SeqSig)
      *)
      else if seq = "pchunked_seq" then (module TestPChunkedSeq : SeqSig)
      else if seq = "pchunked_stack_copy_on_write" then (module TestPChunkedStackCopyOnWrite : SeqSig)
      else if seq = "pchunked_stack_copy_on_write_16" then (module TestPChunkedStackCopyOnWrite16 : SeqSig)
      else if seq = "pchunked_stack_persistence" then (module TestPChunkedStackPersistence : SeqSig)
      else 
        if    (seq = "ocaml_buffer" || seq = "pchunked_string")
           && List.mem testname [ "real_string_buffer"; "real_lifo"; "real_fifo" ]
           then (module TestSizedArray : SeqSig) (* dummy *)
           else failwith "unsupported seq mode"
      in
   let module Seq = (val seq_module : SeqSig) in 
   let module Test = (Scenari(Seq)) in

   let n = Cmdline.parse_or_default_int "n" 10000000 in 
   let r = Cmdline.parse_or_default_int "r" (-1) in 
   let length = Cmdline.parse_or_default_int "length" (-1) in 
   let (r,length) =
      if List.mem testname [ "lifo_1"; "fifo_1"; "real_lifo"; "real_fifo" ] then begin
        if r = -1 && length <> -1 then (n / length, length)
        else if r <> -1 && length = -1 then (r, n / r)
        else failwith "need to provide exactly one of length or r argument"
      end else if testname = "real_string_buffer" && length < 2 then
        failwith "invalid value for length"
      else (r,length)
      in
   (* TODO
   let b = Cmdline.parse_or_default_int "b" 1000 in 
   let g = Cmdline.parse_or_default_int "g" 1 in 
   *)
   let seed = Cmdline.parse_or_default_int "seed" 1 in 
   Random.init seed;
   let testnames = [ 
      "real_lifo", real_lifo seq n r;
      "real_fifo", real_fifo seq n r;
      "real_string_buffer", real_string_buffer seq n length;
      "fifo_1", Test.fifo_1 n r;
      "lifo_1", Test.lifo_1 n r;
      "fifo_debug_1", Test.fifo_debug_1;
      "lifo_debug_1", Test.lifo_debug_1;
      (* TODO
      "split_debug_1", Test.split_debug_1;
      "merge_debug_1", Test.merge_debug_1;
      "merge_debug_2", Test.merge_debug_2 n r;
      "split_merge_1", Test.split_merge_1 n r b; *) ] in
   let test_func = select testnames testname () in
   measured_run test_func

