open Printf
open Shared


(****************************************************************************)
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

(****************************************************************************)

module type SeqSig = SeqSig.S
module type PSeqSig = PSeqSig.S

module RefList : SeqSig = SeqSig.SeqOfPSeq(PList)

module SizedList : SeqSig = SeqSig.SeqOfPSeq(PSizedList)


let size_for_static_array = Cmdline.parse_or_default_int "static_array_size" 20000000
  (* enough to fit all items from experiments *)

let chunk_size = (Cmdline.parse_or_default_int "chunk" 256) 
  (* use 3 for debugging *)

module Capacity : CapacitySig.S = struct let capacity = chunk_size end

module Capacity16 : CapacitySig.S = struct let capacity = 16 end

module Capacity256 : CapacitySig.S = struct let capacity = 256 end

module Capacity4096 : CapacitySig.S = struct let capacity = 4096 end


module ChunkStackArray (Capacity : CapacitySig.S) =
struct
   include UnsupportedSingleEnded
   include UnsupportedExtra
   include StackArray
   let create d = make Capacity.capacity d
end

(*
  type 'a t = {
    data : 'a array;
    mutable size : int; }

  let make capacity d = 
    { data = Array.make capacity d;
      size = 0; }

  let length s =
    s.size 

  let is_empty s =
    s.size = 0

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
*)

module Chunk : SeqSig = ChunkStackArray(Capacity) 
  (* CircularArray.Make(Capacity) *)

(* best for copy on write chunks *)
module Chunk16 : SeqSig = ChunkStackArray(Capacity16)

(* best for ephemeral stack; 128 is ok too *)
module Chunk256 : SeqSig = ChunkStackArray(Capacity256)

module PStackMiddle : PSeqSig = PSizedList
  (* PChunkedSeq *)

module StackMiddle : SeqSig = SizedList
(*struct
   include 
   let transfer_to_back = (fun _ _ -> raise Unsupported)
   let carve_back_at = (fun _ _ -> raise Unsupported)
   let iter = (fun _ _ -> raise Unsupported)
   let fold_left = (fun _ _ _ -> raise Unsupported)
   let fold_right = (fun _ _ _ -> raise Unsupported)
   include UnsupportedBackFront
end*)




  (* SeqSig.SeqOfPSeq(PChunkedSeq) *)
(* for debugging:
  CircularArray.Make(
    struct let capacity = 1 + size_for_static_array / chunk_size end)
*)




(****************************************************************************)

(** OCaml Array *)

module TestStackArray =
struct
   include StackArray
   let create d = 
      make size_for_static_array d
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

module TestStdlibQueue : SeqSig =
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

module TestRefList : SeqSig = RefList

(** Sized List -- TODO RENAME *)

module TestSizedList : SeqSig = SeqSig.SeqOfPSeq(
  PSizedList)

(** Sized Two Lists -- TODO RENAME  *)

module TestSizedTwoLists : SeqSig = SeqSig.SeqOfPSeq(
  PSizedTwoLists)

(** Persistant Chunk *)

module TestPChunkArrayRef : SeqSig = SeqSig.SeqOfPSeq(
  PChunkArray)

(** Persistant Chunk *)

module TestPChunkStackRef : SeqSig = SeqSig.SeqOfPSeq(
  PChunkStack.Make(Capacity))

(** Ephemeral Chunked Stack *)

module TestChunkedStack : SeqSig = struct
  include ChunkedStack.Make(Capacity)(Chunk)(StackMiddle)
  include UnsupportedBackFront
end

module TestChunkedStack256 : SeqSig = struct
  include ChunkedStack.Make(Capacity256)(Chunk256)(StackMiddle)
  include UnsupportedBackFront
end

(* ChunkedStack Indirect *)

module TestChunkedStack256Indirect = 
  StackIndirect.Make(TestChunkedStack256)

(* StackPacked *)

module TestStackPackedRef : SeqSig = SeqSig.SeqOfPSeq(struct
  include StackPacked.Make(Capacity)
  include UnsupportedBackFront
  include UnsupportedSingleEnded
  include UnsupportedExtra
end)

module TestStackPacked256 =
  StackPacked.Make(Capacity256)
   

(** Ephemeral Chunked Seq *)

(* TODO
module TestChunkedSeq : SeqSig = struct
  include ChunkedSeq.Make(Capacity)(Chunk)(StackMiddle)
  include UnsupportedExtra
end
*)
   
(** Pure Chunked Seq *)

module TestPChunkedSeqRef : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedSeq)

(** Chunked Stack Copy on Write *)

module PChunkedStackCopyOnWrite : PSeqSig = 
  PChunkedStack.Make(Capacity)(PChunkArray)(PStackMiddle)

module TestPChunkedStackCopyOnWrite : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackCopyOnWrite)

module PChunkedStackCopyOnWrite16 : PSeqSig = 
  PChunkedStack.Make(Capacity16)(PChunkArray)(PStackMiddle)

module TestPChunkedStackCopyOnWrite16 : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackCopyOnWrite16)

(** PChunked Stack *)

module PChunkedStackRef : PSeqSig = 
  PChunkedStack.Make(Capacity)(PChunkStack.Make(Capacity))(PStackMiddle)

module TestPChunkedStackRef : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackRef)

module PChunkedStackRef256 : PSeqSig = 
  PChunkedStack.Make(Capacity256)(PChunkStack.Make(Capacity256))(PStackMiddle)

module TestPChunkedStackRef256 : SeqSig = SeqSig.SeqOfPSeq(
  PChunkedStackRef256)

(** Chunked String *)

module TestChunkedString =
  ChunkedString.Make(Capacity)(PStackMiddle)

module TestChunkedString4096 =
  ChunkedString.Make(Capacity4096)(PStackMiddle)

(** PChunked String  *)

module TestPChunkedString =
  PChunkedString.Make(Capacity)(PStackMiddle)

module TestPChunkedString4096 =
  PChunkedString.Make(Capacity4096)(PStackMiddle)


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
   for j = 0 to repeat-1 do
      for i = 0 to block-1 do
         Seq.push_back (!a) q;
         incr a;
      done;
      for i = 0 to block-1 do
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
   for j = 0 to repeat-1 do
     for i = 0 to block-1 do
        Seq.push_back (!a) q;
        incr a;
     done;
     if gc_major then Gc.major();
     for i = 0 to block-1 do
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

  module SeqRef = TestRefList 
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

exception Error

let check i j =
  if i <> j then raise Error


(* todo: test get expected number ! *)

let real_lifo seq nbitems repeat () () = 
   begin
   assert (repeat > 0);
   let block = nbitems / repeat in
   printf "length %d\n" block;
   if seq = "list_ref" then begin

      let r = ref [] in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := i::!r;
        done;
        for i = 0 to block-1 do
           match !r with
           | [] -> assert false
           | x::t -> check x (block-i-1); r := t
        done;
     done

   end else if seq = "pchunked_seq_ref" then begin

      let r = ref PChunkedSeq.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := PChunkedSeq.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = PChunkedSeq.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "pchunked_stack_copy_on_write_ref_16" then begin

      let r = ref PChunkedStackCopyOnWrite16.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := PChunkedStackCopyOnWrite16.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = PChunkedStackCopyOnWrite16.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "pchunked_stack_copy_on_write_ref" then begin

      let r = ref PChunkedStackCopyOnWrite.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := PChunkedStackCopyOnWrite.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = PChunkedStackCopyOnWrite.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "pchunked_stack_ref" then begin

      let r = ref PChunkedStackRef.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := PChunkedStackRef.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = PChunkedStackRef.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "pchunked_stack_ref_256" then begin

      let r = ref PChunkedStackRef256.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := PChunkedStackRef256.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = PChunkedStackRef256.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "chunked_stack" then begin

      let r = TestChunkedStack.create def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestChunkedStack.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestChunkedStack.pop_back r in
           check x (block-i-1);
        done;
     done

   end else if seq = "chunked_stack_256" then begin

      let r = TestChunkedStack256.create def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestChunkedStack256.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestChunkedStack256.pop_back r in
           check x (block-i-1);
        done;
     done

  (*
   end else if seq = "chunked_stack_256_indirect" then begin

      let r = ref TestChunkedStack256Indirect.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := TestChunkedStack256Indirect.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let ((x:int),t) = TestChunkedStack256Indirect.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done
  *)

   end else if seq = "stack_packed_256" then begin

      let r = ref TestStackPacked256.empty in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           r := TestStackPacked256.push_back i !r;
        done;
        for i = 0 to block-1 do 
           let (x,t) = TestStackPacked256.pop_back !r in
           check x (block-i-1);
           r := t
        done;
     done

   end else if seq = "vector" then begin

      let r = TestVector.create def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestVector.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestVector.pop_back r in
           check x (block-i-1);
        done;
     done

   end else if seq = "circular_array_big" then begin

      let r = TestCircularArrayBig.create def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestCircularArrayBig.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestCircularArrayBig.pop_back r in
           check x (block-i-1);
        done;
     done

   end else if seq = "stack_array" then begin

      let r = TestStackArray.make block def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestStackArray.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestStackArray.pop_back r in
            check x (block-i-1);
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
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestCircularArrayBig.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestCircularArrayBig.pop_front r in
           check x i;
        done;
     done

   end else if seq = "ocaml_queue" then begin

      let r = TestStdlibQueue.create def in
      for j = 0 to repeat-1 do
        for i = 0 to block-1 do
           TestStdlibQueue.push_back i r;
        done;
        for i = 0 to block-1 do
           let x = TestStdlibQueue.pop_front r in
           check x i;
        done;
     done

   end else failwith "unsupported seq for scenario real_fifo"

let real_string_buffer seq max_word_length nbitems repeat () () = 
   assert (repeat > 0);
   let block = nbitems / repeat in
   printf "length %d\n" block;

  let words = Array.init max_word_length (fun i ->
     Bytes.make i 'x') in
  let nb = ref 0 in
  let _c = ref 0 in
  let next_word () =
     (*let k = Random.int max_word_length in *)
     let k = !_c in
     incr _c;
     if !_c = max_word_length 
       then _c := 0;
     
     let w = words.(k) in
     nb := !nb + k;
     w in

  if seq = "stdlib_buffer" then begin

      for j = 0 to repeat-1 do
        nb := 0;
        let s = Buffer.create 0 in
        while !nb < block do
          let w = next_word() in
          Buffer.add_bytes s w;
        done
      done

  end else if seq = "pchunked_string" then begin

      for j = 0 to repeat-1 do
        nb := 0;
        let r = ref TestPChunkedString.empty in
        while !nb < block do
          let w = next_word() in
          r := TestPChunkedString.add_bytes w !r;
        done
      done

  end else if seq = "pchunked_string_4096" then begin

      for j = 0 to repeat-1 do
        nb := 0;
        let r = ref TestPChunkedString4096.empty in
        while !nb < block do
          let w = next_word() in
          r := TestPChunkedString4096.add_bytes w !r;
        done
      done

  end else if seq = "chunked_string" then begin

      for j = 0 to repeat-1 do
        nb := 0;
        let s = TestChunkedString.create() in
        while !nb < block do
          let w = next_word() in
          TestChunkedString.add_bytes w s;
        done
      done

  end else if seq = "chunked_string_4096" then begin

      for j = 0 to repeat-1 do
        nb := 0;
        let s = TestChunkedString4096.create() in
        while !nb < block do
          let w = next_word() in
          TestChunkedString4096.add_bytes w s;
        done
      done

   end else failwith "unsupported seq for scenario real_string_buffer"


(* TODO: a string_buffer_debug function *)


(****************************************************************************)


let real_test_buckets seq nb_items nb_buckets () () =

  let next_item () = 
    1 in
  let b = ref 0 in
  let next_bucket () =
    let i = !b in 
    incr b; 
    if !b = nb_buckets
      then b := 0;
    i in

  if seq = "list" then begin

    let t = Array.make nb_buckets [] in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- next_item() :: t.(b);
    done

  end else if seq = "chunked_stack_256" then begin
    (* warning: big memory overhead if nb_buckets is large, might overflow *)

    let t = Array.make nb_buckets (TestChunkedStack256.create 0) in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      TestChunkedStack256.push_back (next_item()) t.(b)
    done

   end else if seq = "chunked_stack_256_indirect" then begin
    (* warning: big memory overhead if nb_buckets is large, might overflow *)

    let t = Array.make nb_buckets TestChunkedStack256Indirect.empty in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- TestChunkedStack256Indirect.push_back (next_item()) t.(b)
    done;
    (* if nb_buckets = 1 then 
      assert (TestChunkedStack256Indirect.length t.(0) = nb_items); *)

   end else if seq = "stack_packed_256" then begin

    let t = Array.make nb_buckets TestStackPacked256.empty in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      t.(b) <- TestStackPacked256.push_back (next_item()) t.(b)
    done

   (*
   end else if seq = "stack_array" then begin

    let t = Array.make nb_buckets (StackArray.make 3000000 0) in
    for i = 0 to nb_items - 1 do
      let b = next_bucket() in
      (*bonus: t.(b) <- push (next_item()) t.(b); *)
      StackArray.push_back (next_item()) t.(b)
    done
   *)

   end else failwith "unsupported seq for scenario real_test_buckets"


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
      if seq = "stack_array" then (module TestStackArray : SeqSig)
      else if seq = "vector" then (module TestVector : SeqSig)
      else if seq = "circular_array_big" then (module TestCircularArrayBig : SeqSig) 
      else if seq = "stdlib_queue" then (module TestStdlibQueue : SeqSig)
      else if seq = "list_ref" then (module TestRefList : SeqSig)
      else if seq = "sized_list" then (module TestSizedList : SeqSig)
      else if seq = "sized_two_lists" then (module TestSizedTwoLists : SeqSig)
      else if seq = "stack_packed" then (module TestStackPackedRef : SeqSig)
      else if seq = "pchunk_array_ref" then (module TestPChunkArrayRef : SeqSig)
      else if seq = "pchunk_stack_ref" then (module TestPChunkStackRef : SeqSig)
      else if seq = "chunked_stack" then (module TestChunkedStack : SeqSig)
      else if seq = "chunked_stack_256" then (module TestChunkedStack256 : SeqSig)
      (* TODO
      else if seq = "chunked_seq" then (module TestChunkedSeq : SeqSig)
      *)
      else if seq = "pchunked_seq_ref" then (module TestPChunkedSeqRef : SeqSig)
      else if seq = "pchunked_stack_copy_on_write_ref" then (module TestPChunkedStackCopyOnWrite : SeqSig)
      else if seq = "pchunked_stack_copy_on_write_ref_16" then (module TestPChunkedStackCopyOnWrite16 : SeqSig)
      else if seq = "pchunked_stack_ref" then (module TestPChunkedStackRef : SeqSig)
      else if seq = "pchunked_stack_ref_256" then (module TestPChunkedStackRef256 : SeqSig)
      else 
        if    (seq = "stdlib_buffer" || seq = "chunked_string"  || seq = "pchunked_string"  || seq = "chunked_string_4096" || seq = "pchunked_string_4096" || seq = "list" || seq ="stack_packed_256")
           && List.mem testname [ "real_string_buffer"; "real_lifo"; "real_fifo"; "real_test_buckets" ]
           then (module TestStackArray : SeqSig) (* dummy *)
           else failwith "unsupported seq mode"
      in
   let module Seq = (val seq_module : SeqSig) in 
   let module Test = (Scenari(Seq)) in

   let n = Cmdline.parse_or_default_int "n" 10000000 in 
   let r = Cmdline.parse_or_default_int "r" (-1) in 
   let max_word_length = Cmdline.parse_or_default_int "max_word_length" (-1) in 
   let _ = if testname = "real_string_buffer" && max_word_length < 2 then
               failwith "invalid value for max_word_length" in
   let nb_buckets = Cmdline.parse_or_default_int "nb_buckets" (-1) in 
   if (testname = "real_test_buckets" && nb_buckets = -1) then 
     failwith "invalid nb_buckets";
   let length = Cmdline.parse_or_default_int "length" (-1) in 
   let (r,length) =
      if List.mem testname [ "lifo_1"; "fifo_1"; "real_lifo"; "real_fifo"; "real_string_buffer" ] then begin
        if r = -1 && length <> -1 then (n / length, length)
        else if r <> -1 && length = -1 then (r, n / r)
        else failwith "need to provide exactly one of length or r argument"
      end else (r,length)
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
      "real_string_buffer", real_string_buffer seq max_word_length n r;
      "real_test_buckets", real_test_buckets seq n nb_buckets;
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

