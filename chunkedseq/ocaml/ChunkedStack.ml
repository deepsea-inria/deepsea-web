
(** Optimized implementation of single-ended chunked sequences.
    Can be used for stacks (push/pop) or bags (same, plus merge
    and split operations, not preserving the order). 
    
    Compared with doubled-ended sequences:
    - middle sequence only contains full chunks
    - back-outer and back-inner chunks are not needed
    - structure is empty iff front-outer buffer is empty
    - merge/split operations do not preserve the order
*)

module Make 
  (Capacity : CapacitySig.S) 
  (Chunk : SeqSig.S) (* chunks of capacity Capacity.value *)
  (Middle : SeqSig.S) 
= struct

(*--------------------------------------------------------------------------*)

type 'a chunk = 'a Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity

(*-----------------------------------------------------------------------------*)

type 'a t = {
   mutable fo : 'a chunk;
   mutable fi : 'a chunk;
   mutable mid : ('a chunk) Middle.t;
   mutable chunks : ('a chunk) array;
   default : 'a; (* note: default could also be read from the outer chunk *)
   }
    
let create d = 
  let def = Chunk.create d in
  let fo = Chunk.create d in
  let fi = Chunk.create d in
  { fo = fo;
    fi = fi;
    mid = Middle.create def;
    chunks = [|fo;fi|];
    default = d; }

let nb_chunks s =
  Middle.length s.mid + 2

let max_nb_chunks s =
  Array.length s.chunks

let length s = 
    Chunk.length s.fo 
  + Chunk.length s.fi
  + (capacity * Middle.length s.mid)

let is_empty s =
   Chunk.is_empty s.fo 
  
let get s i =
  assert (i >= 0 && i < length s);
  let k = i / capacity in
  (* i lsr log_capacity *)
  let r = i mod capacity in
  Chunk.get s.chunks.(k) r

let set s i v =
  assert (i >= 0 && i < length s);
  let k = i / capacity in
  let r = i mod capacity in
  Chunk.set s.chunks.(k) r v

let push_back_chunk c s =
  let n = nb_chunks s in
  let m = max_nb_chunks s in
  (* Printf.printf "push_back chunk %d %d\n" n m; *)
  if n = m then begin
    (* Printf.printf "resize from %d to %d\n" m (2*m); *)
    let def = s.chunks.(0) in
    let t = Array.make (2*m) def in
    Array.blit s.chunks 0 t 0 n;
    s.chunks <- t;
  end;
  s.chunks.(n) <- c

let push_back x s =
   let co = s.fo in
   if is_full co then begin
      let ci = s.fi in
      s.fi <- co;
      if Chunk.is_empty ci then begin
         s.fo <- ci;
      end else begin
         let c = Chunk.create s.default in
         push_back_chunk c s; (* must be done before extending middle length *)
         Middle.push_back ci s.mid;
         s.fo <- c;
      end 
   end;
   Chunk.push_back x s.fo

let pop_back_chunk s =
  let n = nb_chunks s in
  let m = max_nb_chunks s in
  if n <= m/4 
    then s.chunks <- Array.sub s.chunks 0 (n/2)

let pop_back s =
  assert (not (Chunk.is_empty s.fo));
  let co = s.fo in
  let x = Chunk.pop_back co in
  if Chunk.is_empty co then begin
    let ci = s.fi in
    if not (Chunk.is_empty ci) then begin
       s.fi <- co;
       s.fo <- ci
    end else if not (Middle.is_empty s.mid) then begin
       s.fo <- Middle.pop_back s.mid;
       pop_back_chunk s (* must be done after popping from middle *)
    end 
  end;
  x

let push_front x s =
  assert false

let pop_front s =
  assert false

let append s1 s2 = 
  assert false

let carve_back_at i s =
  assert false

let merge s1 s2 = 
  assert false (* TODO *)
     
let split i s = 
  assert false (* TODO *)

let iter f s =
  Chunk.iter f s.fo;
  Chunk.iter f s.fi;
  Middle.iter (fun c -> Chunk.iter f c) s.mid

let fold_left f a0 s =
  let a1 = Chunk.fold_left f a0 s.fo in
  let a2 = Chunk.fold_left f a1 s.fi in
  Middle.fold_left (fun a c -> Chunk.fold_left f a c) a2 s.mid

let fold_right f s a0 =
  Chunk.fold_right f s.fo (
  Chunk.fold_right f s.fi (
  Middle.fold_right (fun c a -> Chunk.fold_right f c a) s.mid a0 
  ))

let to_list s =
  fold_right (fun x a -> x::a) s []

let transfer_to_back _ _ =
  assert false


end