module PChunkedSeq =
  struct

    type 'a weight_fn = 'a Chunk.weight_fn

    let unit_weight_fn : 'a weight_fn = fun _ -> 1

    type 'a t = 'a PChunkedWeightedSeq.chunkedseq

    let push_front x cs =
      PChunkedWeightedSeq.push_front' unit_weight_fn (cs, x)

    let push_back  x cs =
      PChunkedWeightedSeq.push_back' unit_weight_fn (cs, x)

    let pop_front cs =
      let (cs', x) = PChunkedWeightedSeq.pop_front' unit_weight_fn cs in
      (x, cs)
                 
    let pop_back cs =
      let (cs', x) = PChunkedWeightedSeq.pop_back' unit_weight_fn cs in
      (x, cs)
        
    let append cs1 cs2 =
      PChunkedWeightedSeq.concat' unit_weight_fn (cs1, cs2)

    let split_at i cs =
      let (cs1, x, cs2) = PChunkedWeightedSeq.split' unit_weight_fn (cs, i) in
      (cs1, push_back x cs2)

    let fold_left f x cs =
      assert false
        
    let fold_right =
      PChunkedWeightedSeq.fold_right

    let list_of cs =
      fold_right (fun x y -> x :: y) cs []
    
  end
