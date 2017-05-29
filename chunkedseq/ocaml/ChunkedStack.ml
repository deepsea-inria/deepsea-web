
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
  (Chunk : SeqSig.S)   (* chunks of capacity Capacity.value *)
  (Middle : SeqSig.S) 
= struct

(*--------------------------------------------------------------------------*)

type 'a chunk = 'a Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity


type 'a t = {
   mutable fo : 'a chunk;
   mutable fi : 'a chunk;
   mutable mid : ('a chunk) Middle.t;
   default : 'a; (* note: default could also be read from the outer chunk *)
   }
    
let create d = 
  let def = Chunk.create d in
  { fo = Chunk.create d;
    fi = Chunk.create d;
    mid = Middle.create def;
    default = d; }

let length s = 
    Chunk.length s.fo 
  + Chunk.length s.fi
  + (capacity * Middle.length s.mid)

let is_empty s =
   Chunk.is_empty s.fo 
  
let push_front x s =
   let co = s.fo in
   if is_full co then begin
      let ci = s.fi in
      s.fi <- co;
      if Chunk.is_empty ci then begin
         s.fo <- ci;
      end else begin
         Middle.push_front ci s.mid;
         s.fo <- Chunk.create s.default;
      end 
   end;
   Chunk.push_front x s.fo

let pop_front s =
  assert (not (Chunk.is_empty s.fo));
  let co = s.fo in
  let x = Chunk.pop_front co in
  if Chunk.is_empty co then begin
    let ci = s.fi in
    if not (Chunk.is_empty ci) then begin
       s.fi <- co;
       s.fo <- ci
    end else if not (Middle.is_empty s.mid) then begin
       s.fo <- Middle.pop_front s.mid
    end 
  end;
  x

(* Alternative code when the front buffer might be left empty 
   while the structure is not empty

  let pop_front s =
    if Chunk.is_empty s.fo begin
      let ci = s.fi in
      if not (Chunk.is_empty ci) then begin
         s.fi <- s.fo;
         s.fo <- ci
      end else if not (Middle.is_empty s.mid) then begin
         s.fo <- Middle.pop_front s.mid
      end else 
         raise Not_found
    end;
    Chunk.pop_front s.fo

  let is_empty () =
       Chunk.is_empty s.fo 
    && Chunk.is_empty s.fi
    && Middle.is_empty s.mid

*)

let push_back x s =
  assert false

let pop_back s =
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


(*--------------------------------------------------------------------------*)

(*
             
  and concat' : 'a. wf:('a weight_fn) -> 'a chunkedseq * 'a chunkedseq -> 'a chunkedseq = fun ~wf (cs1, cs2) ->
    if empty cs1 then
      cs2
    else if empty cs2 then
      cs1
    else
      match (cs1, cs2) with
      | (Shallow c1, _) ->
         transfer_contents_front wf (cs2, c1)
      | (_, Shallow c2) ->
         transfer_contents_back wf (cs1, c2)
      | (Deep (_, {fo=fo1; fi=fi1; mid=mid1; bi=bi1; bo=bo1}),
         Deep (_, {fo=fo2; fi=fi2; mid=mid2; bi=bi2; bo=bo2})) ->
           let mid1' = push_buffer_back Chunk.weight (mid1, bi1) in
           let mid1'' = push_buffer_back Chunk.weight (mid1', bo1) in
           let mid2' = push_buffer_front Chunk.weight (mid2, fi2) in
           let mid2'' = push_buffer_front Chunk.weight (mid2', fo2) in
           let (mid1''', mid2''') =
             if empty mid1'' || empty mid2'' then
               (mid1'', mid2'')
             else
               let (mid1''', c1) = pop_back' Chunk.weight mid1'' in
               let (mid2''', c2) = pop_front' Chunk.weight mid2'' in
               if Chunk.weight c1 + Chunk.weight c2 <= Chunk.k then
                 let c' = Chunk.concat wf (c1, c2) in
                 (push_back' Chunk.weight (mid1''', c'), mid2''')
               else
                 (mid1'', mid2'')
           in
           let mid12 = concat' Chunk.weight (mid1''', mid2''') in
           mk_deep' wf {fo=fo1; fi=fi1; mid=mid12; bi=bi2; bo=bo2}
                    
  and split' : 'a. wf:('a weight_fn) -> ('a chunkedseq * int) -> ('a chunkedseq * 'a * 'a chunkedseq) = fun ~wf (cs, i) ->
    match cs with
    | Shallow c ->
        let (c1, x, c2) = Chunk.split wf (c, i) in
        (Shallow c1, x, Shallow c2)
    | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
        let (wfo, wfi) = (Chunk.weight fo, Chunk.weight fi) in
        let wm = weight mid in
        let (wbi, wbo) = (Chunk.weight bi, Chunk.weight bo) in
        let (cs1, x, cs2) =
          if i < wfo then
            let (fo1, x, fo2) = Chunk.split wf (fo, i) in
            let cs1 = mk_deep {fo=fo1; fi=ec; mid=create; bi=ec; bo=ec} in
            let cs2 = mk_deep {d with fo=fo2} in
            (cs1, x, cs2)
    else if i < wfo + wfi then
            let j = i - wfo in
      let (fi1, x, fi2) = Chunk.split wf (fi, j) in
      let cs1 = mk_deep {d with fi=ec; mid=create; bi=ec; bo=fi1} in
      let cs2 = mk_deep {d with fo=fi2; fi=ec} in
      (cs1, x, cs2)
          else if i < wfo + wfi + wm then
            let j = i - wfo - wfi in
            let (mid1, c, mid2) = split' Chunk.weight (mid, j) in
            let (c1, x, c2) = Chunk.split wf (c, j - weight mid1) in
            let cs1 = mk_deep {d with mid=mid1; bi=ec; bo=c1} in
            let cs2 = mk_deep {d with fo=c2; fi=ec; mid=mid2} in
            (cs1, x, cs2)
          else if i < wfo + wfi + wm + wbi then
      let (bi1, x, bi2) = Chunk.split wf (bi, i - wfo - wfi - wm) in
      let cs1 = mk_deep {d with bi=ec; bo=bi1} in
      let cs2 = mk_deep {d with fo=bi2; fi=ec; mid=create; bi=ec} in
      (cs1, x, cs2)
          else if i < wfo + wfi + wm + wbi + wbo then
      let (bo1, x, bo2) = Chunk.split wf (bo, i - wfo - wfi - wm - wbi) in
      let cs1 = mk_deep {d with bo=bo1} in
      let cs2 = mk_deep {fo=bo2; fi=ec; mid=create; bi=ec; bo=ec} in
      (cs1, x, cs2)
    else
            failwith "Chunkedseq.split: out of bounds"
        in
        (check wf cs1, x, check wf cs2)

*)

end