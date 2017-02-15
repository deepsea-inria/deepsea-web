
module Chunk =
  struct

    let k = 32

    type 'a t = int list

    let tabulate = List.tabulate

end


type 'a chunkedseq
  = Shallow of 'a  Chunk.t
  | Deep of int * 'a deep

 and 'a deep = {
    fo : 'a Chunk.t; fi : 'a Chunk.t;
    mid : ('a Chunk.t) chunkedseq;
    bi : 'a Chunk.t; bo : 'a Chunk.t;
  }


