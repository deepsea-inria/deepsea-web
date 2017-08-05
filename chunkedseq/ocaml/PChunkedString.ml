
(** Optimized implementation of single-ended chunked sequence of bytes.
    
    Compared with PChunkedStack:
    - specialized to bytes
    - hardcode the use of PChunkBytesBuffer
*)

module Make 
  (Capacity : CapacitySig.S) 
  (Middle : PSeqSig.S) 
= struct

module Chunk = PChunkBytesBuffer.Make(Capacity)

(*--------------------------------------------------------------------------*)

type chunk = Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity

(*-----------------------------------------------------------------------------*)

type t = {
   fo : chunk;
   mid : chunk Middle.t;
   }
    
let empty = 
  { fo = Chunk.empty;
    mid = Middle.empty }

let length s = 
    Chunk.length s.fo 
  + (capacity * Middle.length s.mid)
  
let add_bytes w s =
  let co = s.fo in
  let n = Chunk.length co in  
  let m = Bytes.length w in
  if n + m <= capacity then begin
    { fo = Chunk.push_bytes w co;
      mid = s.mid } 
  end else begin (* m > capacity - n = r *)
    let m0 = capacity - n in
    let c0 = Chunk.push_bytes_of w 0 m0 co in
    let new_mid = ref (Middle.push_back c0 s.mid) in
    let mdone = ref m0 in
    while m - !mdone > capacity do
      let c = Chunk.create_of_bytes w !mdone capacity in
      new_mid := Middle.push_back c !new_mid;
      mdone := !mdone + capacity;
    done;
    { fo = Chunk.create_of_bytes w !mdone (m - !mdone);
      mid = !new_mid; } 
  end

end