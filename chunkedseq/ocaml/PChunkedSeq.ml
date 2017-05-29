
module S = PChunkedWeightedSeq

type 'a weight_fn = 'a S.Chunk.weight_fn

let unit_weight_fn : 'a weight_fn = fun _ -> 1

type 'a t = 'a S.chunkedseq

let push_front x cs =
  S.push_front' unit_weight_fn (cs, x)

let push_back  x cs =
  S.push_back' unit_weight_fn (cs, x)

let pop_front cs =
  let (cs', x) = S.pop_front' unit_weight_fn cs in
  (x, cs)
             
let pop_back cs =
  let (cs', x) = S.pop_back' unit_weight_fn cs in
  (x, cs)
    
let append cs1 cs2 =
  S.concat' unit_weight_fn (cs1, cs2)

let split_at i cs =
  let (cs1, x, cs2) = S.split' unit_weight_fn (cs, i) in
  (cs1, push_back x cs2)

let fold_left f x cs = assert false
    
let fold_right =
  S.fold_right

let list_of cs =
  fold_right (fun x y -> x :: y) cs []
    
let fold_right = S.fold_right

let list_of cs = fold_right (fun x y -> x :: y) cs []

