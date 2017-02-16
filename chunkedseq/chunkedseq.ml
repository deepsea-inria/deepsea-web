
module Chunk =
  struct

    let k = 32

    (* weight, chunk contents *)
    type 'a t = int * int list

    let tabulate ((w, n), f) =
      let rec tab i =
        if i < 0 then
          []
        else
          f i :: tab (i - 1)
      in
      tab (n - 1)

    let sub (c, i) = List.nth c i

    let size = List.length

                 
      
end


type 'a chunkedseq
  = Shallow of 'a  Chunk.t
  | Deep of int * 'a deep

 and 'a deep = {
    fo : 'a Chunk.t; fi : 'a Chunk.t;
    mid : ('a Chunk.t) chunkedseq;
    bi : 'a Chunk.t; bo : 'a Chunk.t;
  }


