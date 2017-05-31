
(** Optimized implementation of single-ended chunked sequence of bytes.
    
    Compared with ChunkedStack:
    - specialized to bytes
    - hardcode the use of ChunkBytesBuffer
*)

module Make 
  (Capacity : CapacitySig.S) 
  (Middle : PSeqSig.S) 
= struct

module Chunk = ChunkBytesBuffer.Make(Capacity)

(*--------------------------------------------------------------------------*)

type chunk = Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity

(*-----------------------------------------------------------------------------*)

type t = {
   mutable fo : chunk;
   mutable mid : chunk Middle.t; }
    
let create () = 
  { fo = Chunk.create();
    mid = Middle.empty }

let length s = 
    Chunk.length s.fo 
  + (capacity * Middle.length s.mid)
  
let add_bytes w s =
  let co = s.fo in
  let n = Chunk.length co in  
  let m = Bytes.length w in
  if n + m <= capacity then begin
    Chunk.push_bytes w co;
  end else begin (* m > capacity - n = r *)
    let m0 = capacity - n in
    Chunk.push_bytes_of w 0 m0 co;
    let new_mid = ref (Middle.push_back co s.mid) in
    let mdone = ref m0 in
    while m - !mdone > capacity do
      let c = Chunk.create_of_bytes w !mdone capacity in
      new_mid := Middle.push_back c !new_mid;
      mdone := !mdone + capacity;
    done;
    s.fo <- Chunk.create_of_bytes w !mdone (m - !mdone);
    s.mid <- !new_mid;
  end

end