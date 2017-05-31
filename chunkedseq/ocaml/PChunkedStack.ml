
(** Optimized implementation of persistent single-ended chunked sequences.
    Can be used for stacks (push/pop) or bags (same, plus merge
    and split operations, not preserving the order). 
    
    Compared with ephemeral single-ended sequences:
    - no front-inner buffer is used
    - the chunks used are persistent (e.g. PChunkArray or PChunkStack)
    - the structure is reallocated every time
    - no default value is needed
*)

module Make 
  (Capacity : CapacitySig.S) 
  (Chunk : PSeqSig.S) (* chunks of capacity Capacity.value *)
  (Middle : PSeqSig.S) 
= struct

(*--------------------------------------------------------------------------*)

type 'a chunk = 'a Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity

(*-----------------------------------------------------------------------------*)

type 'a t = {
   fo : 'a chunk;
   mid : ('a chunk) Middle.t; }
    
let empty = 
  { fo = Chunk.empty;
    mid = Middle.empty; }

let length s = 
    Chunk.length s.fo 
  + (capacity * Middle.length s.mid)

let is_empty s =
   Chunk.is_empty s.fo 
  
let push_back x s =
   let co = s.fo in
   if is_full co then begin
     { fo = Chunk.push_back x Chunk.empty;
       mid = Middle.push_back co s.mid; }
   end else begin
     { fo = Chunk.push_back x s.fo;
       mid = s.mid; }
   end

let pop_back s =
  assert (not (Chunk.is_empty s.fo));
  let co = s.fo in
  let (x,co2) = Chunk.pop_back co in
  let s2 = 
    if Chunk.is_empty co2 then begin
      if Middle.is_empty s.mid then begin
        { fo = co2; mid = s.mid; }  
      end else begin
        let (co3,mid2) = Middle.pop_back s.mid in
        { fo = co3; mid = mid2; }
      end 
    end else begin
      { fo = co2; mid = s.mid; }
    end in
  (x, s2)

(*-----------------------------------------------------------------------------*)

let front s =
  assert false

let back s =
  assert false

let push_front x s =
  assert false

let pop_front s =
  assert false

let append s1 s2 = 
  assert false

let merge s1 s2 = 
  assert false (* TODO *)
     
let split_at i s = 
  assert false (* TODO *)

(*-----------------------------------------------------------------------------*)

let iter f s =
  Chunk.iter f s.fo;
  Middle.iter (fun c -> Chunk.iter f c) s.mid

let fold_left f a0 s =
  let a1 = Chunk.fold_left f a0 s.fo in
  Middle.fold_left (fun a c -> Chunk.fold_left f a c) a1 s.mid

let fold_right f s a0 =
  Chunk.fold_right f s.fo (
  Middle.fold_right (fun c a -> Chunk.fold_right f c a) s.mid a0 
  )

let to_list s =
  fold_right (fun x a -> x::a) s []


end