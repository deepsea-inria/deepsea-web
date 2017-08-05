      val create : unit -> 'a Seq.t
   val create : unit -> t
   val create : unit -> 'a t


(** garbage *)

type 'a split_at_or_length = 
  | SplitAt of 'a list * 'a list
  | SplitAtFailed of int (* length *)

let rec list_split_at_or_length len n l =
   if n = 0 then ([],l) else
   match l with
   | [] -> SplitAtFailed len
   | x::r -> 
      let (a,b) = list_split_at (n-1) r in
      (x::a,b)

      let split_at i s =
  match list_split_at_or_length 0 i s.front with

  try 
    let (l1,l2) =  in
     ({ size = i; 
        front = l1;
        back = [] },
      { size = s.size - i; 
        front = l2;
        back = s.back } )
  with Not_found ->
    let (l1,l2) = list_split_at i s.back in
     ({ size = i; 
        front = s.front;
        back = s.back },
      { size = s.size - i; 
        data = l2;
        back = s.back } )


(*-----------------------------------------------------------------------------*)

module Make (Item : MeasuredType.S)
  : (PureMeasuredSeq.S with type item = Item.t and type meas = int) = 
struct
   include FingerTree.Make(ReducerCount(Item))
end




module FFTreeListInt = FFTreeList.Make
      (IntInhabType)
      (Chunk)
      (FingerTreeNbInlined.Make)
      (*
module FFTreeListHybridInt = 
   FFTreeListHybrid.Make
      (IntInhabType)
      (Chunk)
      (FingerTreeNbInlined.Make)
*)



let real_fifo seq nbitems repeat () () =
   assert (repeat > 0);
   let block = nbitems / repeat in
   printf "length %d\n" block;
   if seq = "batched_queue" then begin

      let r = ref BatchedQueue.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := BatchedQueue.push_back 1 !r;
        done;
        for i = 1 to block do
           let (_,t) = BatchedQueue.pop_front !r in
           r := t;
        done;
     done

   end else if seq = "fftree_list" then begin

      let r = ref FFTreeListInt.empty in
      for j = 1 to repeat do
        for i = 1 to block do
           r := FFTreeListInt.push_back 1 !r;
        done;
        for i = 1 to block do
           let (_,t) = FFTreeListInt.pop_front !r in
           r := t
        done;
     done

   end else if seq = "circular_array" then begin

      let r = Test_Circular_Array.create() in
      for j = 1 to repeat do
        for i = 1 to block do
           Test_Circular_Array.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = Test_Circular_Array.pop_front r in
           ()
        done;
     done

   end else if seq = "boot_seq" then begin

      let r = Test_Boot_Seq.create() in
      for j = 1 to repeat do
        for i = 1 to block do
           Test_Boot_Seq.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = Test_Boot_Seq.pop_front r in
           ()
        done;
     done


   (*
   end else if seq = "ocaml_queue" then begin

      let r = Test_Ocaml_Queue.create() in
      for j = 1 to repeat do
        for i = 1 to block do
           Test_Ocaml_Queue.push 1 r;
        done;
        for i = 1 to block do
           let _t = Test_Ocaml_Queue.pop r in
           ()
        done;
     done
*)

   end else if seq = "fftree_buffer_move" then begin

      let r = Test_FFtree_Buffer_Move.create() in
      for j = 1 to repeat do
        for i = 1 to block do
           Test_FFtree_Buffer_Move.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = Test_FFtree_Buffer_Move.pop_front r in
           ()
        done;
     done

   end else if seq = "fftree_buffer_move_inlined" then begin

      let r = Test_FFtree_Buffer_Move_Inlined.create() in
      for j = 1 to repeat do
        for i = 1 to block do
           Test_FFtree_Buffer_Move_Inlined.push_back 1 r;
        done;
        for i = 1 to block do
           let _t = Test_FFtree_Buffer_Move_Inlined.pop_front r in
           ()
        done;
     done

   end else failwith "unsupported seq for scenario real_fifo"

let real_random_access seq nbitems repeat gap () =
   assert (gap <= nbitems);
   if seq = "circular_array" then begin
      let tot = ref 0 in
      let pos = ref 0 in
      let r = Test_Circular_Array.create() in
      for i = 1 to nbitems do
         if (Random.int 2) = 0 then 
            Test_Circular_Array.push_back i r
         else
            Test_Circular_Array.push_front i r;
      done;
      fun () -> begin
         for i = 1 to repeat do
            let v = Test_Circular_Array.get r !pos in
            tot := !tot + v;
            pos := !pos + gap;
            if !pos >= nbitems then
               pos := !pos - nbitems;
         done;
         printf "result %d\n" !tot;
      end

   end else if seq = "fftree_buffer_move" then begin

      let tot = ref 0 in
      let pos = ref 0 in
      let r = Test_FFtree_Buffer_Move.create() in
      for i = 1 to nbitems do
         if (Random.int 2) = 0 then 
            Test_FFtree_Buffer_Move.push_back i r
         else
            Test_FFtree_Buffer_Move.push_front i r;
      done;
      fun () -> begin
         let rinfo = Test_FFtree_Buffer_Move.build_info r in
         for i = 1 to repeat do
            let v = Test_FFtree_Buffer_Move.get rinfo !pos in
            tot := !tot + v;
            pos := !pos + gap;
            if !pos >= nbitems then
               pos := !pos - nbitems;
         done;
         printf "result %d\n" !tot;
      end

   end else failwith "unsupported seq for scenario random_access"


(****************************************************************************)

module UnsupportedExtra =
struct
   let length = (fun _ -> raise Unsupported)
   let concat = (fun _ _ -> raise Unsupported)
   let split_at = (fun _ _ -> raise Unsupported)
   let fold_left = (fun _ _ _ -> raise Unsupported)
   let fold_right = (fun _ _ _ -> raise Unsupported)
end

module type OkasakiPureSeq = (* temp *)
sig 
   type 'a t
   val empty : 'a t
   val is_empty : 'a t -> bool
   val push_front : 'a -> 'a t -> 'a t
   val pop_front : 'a t -> 'a * 'a t
   val push_back : 'a -> 'a t -> 'a t
   val pop_back : 'a t -> 'a * 'a t
   val to_list : 'a t -> 'a list 
end

module PureofOkasakiPureSeq (Seq : OkasakiPureSeq) 
  : (PureSeq.S with type item = int) = 
struct
   type item = int
   type t = item Seq.t
   include (Seq : sig 
      val empty : t
      val is_empty : t -> bool
      val push_front : item -> t -> t
      val pop_front : t -> item * t
      val push_back : item -> t -> t
      val pop_back : t -> item * t
      val to_list : t -> item list
   end)
   include UnsupportedExtra
end

module type ISeq = (ImpSeq.S with type item = int)


(****************************************************************************)

module IntType = 
struct 
   type t = int 
end

module IntMeasuredType =
struct
   type t = int 
   let length x = 1
end

module IntInhabType = 
struct 
   type t = int 
   let inhab = 0 
   let print = string_of_int 
end


       "real_random_access", real_random_access seq n r g;


      (* "random_access_debug_1", random_access_debug_1 seq n *) 
(****************************************************************************)
(*

  module FFtreeMove = Test_FFtree_Buffer_Move
  module Buf = FFtreeMove.Buf

  let build_random_sequence n_items = (* items labelled 0 to n_items-1 *)
     let r = ref (FFtreeMove.create()) in
     let n = ref n_items in
     let k = chunk_size in
     let a = ref 0 in
     while !n > 0 do
        let p = 1 + Random.int k in
        let p = min p !n in
        n := !n - p;
        let s = FFtreeMove.create() in
        for i = 1 to p do 
           FFtreeMove.push_back !a s;
           incr a;
        done;
        r := FFtreeMove.concat !r s;
     done;
     assert (FFtreeMove.length !r = n_items);
     FFtreeMove.iter_chunks (fun buf -> printf "(%d,%d) " buf.Buf.head buf.Buf.size; Buf.iter (fun v -> printf "%d " v) buf; printf "| ") !r; print_newline();
     !r

  let random_access_debug_1 seq n_items () () =
     if seq <> "fftree_buffer_move" then failwith "unsupported seq for scenario random_access_debug_1";
     let r = build_random_sequence n_items in
     printf "built"; print_newline();
     let rinfo = FFtreeMove.build_info r in
     printf "info"; print_newline();
     Array.iteri (fun idinfo item ->
           let bits = FFtreeMove.bits in
           let mbits = 1 lsl bits in
           let ind = item.FFtreeMove.indices in
           let n1 = ind mod mbits in   
           let h1 = (ind lsr (1*bits)) mod mbits in   
           let n2 = (ind lsr (2*bits)) mod mbits in   
           let h2 = (ind lsr (3*bits)) mod mbits in   
           let h3 = (ind lsr (4*bits)) mod mbits in   
           printf "%d: n1=%d h1=%d n2=%d h2=%d h3=%d\n" idinfo n1 h2 n2 h2 h3;
           let b1 = { Buf.data = item.FFtreeMove.currtab; Buf.head = h1; Buf.size = n1 } in
           let b2 = { Buf.data = item.FFtreeMove.nexttab; Buf.head = h2; Buf.size = n2 } in
           printf "---currtab:"; Buf.iter (fun v -> printf "%d " v) b1; printf "\n";
           printf "---nexttab:"; Buf.iter (fun v -> printf "%d " v) b2; printf "\n";)
        rinfo;
     printf "printed"; print_newline();
     for i = 0 to pred n_items do
        let v = FFtreeMove.get rinfo i in
        printf "%d" i; print_newline();
        if (v <> i) then failwith (sprintf "expected %d obtained %d" i v);
     done
*)