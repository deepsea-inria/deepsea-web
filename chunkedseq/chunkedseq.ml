
module Chunk =
  struct

    let k = 32

    type weight = int

    type 'a weight_fn = ('a -> weight)

    type 'a chunk = weight * 'a list

    let create = (0, [])
                      
    let size (_, xs) = List.length xs
                 
    let sub ((_, xs), i) = List.nth xs i

    let back (_, xs) = List.hd xs

    let front c = sub (c, size c - 1)

    let push_back wf ((w, xs), x) = (w + wf x, x :: xs)
                                      
    let push_front wf ((w, xs), x) = (w + (wf x), List.append xs [x])

    let pop_back wf (w, xs) =
      match xs with
      | x :: xs -> ((w - wf x, xs), x)
      | _ -> failwith "bogus"

    let pop_front wf (w, xs) =
      match List.rev xs with
      | x :: xs -> ((w - wf x, List.rev xs), x)
      | _ -> failwith "bogus"

    let concat _ ((w1, xs1), (w2, xs2)) = (w1 + w2, List.append xs1 xs2)

    let sigma wf (_, xs) =
      let sum = List.fold_left (fun x y -> x + y) 0 in
      sum (List.map wf xs)

    let split : 'a. ('a weight_fn) -> ('a chunk * weight) -> ('a chunk * 'a * 'a chunk) = fun wf ((_, xs), i) ->
      let rec f (xs1, xs2, wxs1) =
        match xs2 with
        | x :: xs2 ->
           let wxs1' = (wf x) + wxs1 in
           let wxs2 = sigma wf (0, xs2) in
           if wxs1' >= i then
             ((wxs1', List.rev xs1), x, (wxs2, xs2))
           else
             f (x :: xs1, xs2, wxs1')
        | [] ->
           failwith ""
      in
      f ([], xs, 0)

    let weight_of (w, _) = w

    let empty c = (size c = 0)

    let full c = (size c = k)

  end

module ChunkedseqSpecification =
  struct

    let create = []
    
    let size = List.length

    let sub = List.nth

    let back = List.hd

    let front = List.tl

    let push_back (xs, x) = x :: xs

    let push_front (xs, x) = List.append xs [x]

    let pop_back = List.tl

    let pop_front xs = List.rev (pop_back (List.rev xs))

    let concat (xs1, xs2) = List.append xs1 xs2

    let split (xs, i) =
      let rec take_drop (n, l) =
        if n = 0 then ([], l) else
          match l with
          | [] -> failwith "bogus"
          | x::l' -> let (h,t) = take_drop (n-1, l') in
                     (x::h, t)
      in
      take_drop (i, xs)
        
  end

module Chunkedseq =
  struct

    type 'a chunk = 'a Chunk.chunk
	  
    type 'a chunkedseq
      = Shallow of 'a chunk
      | Deep of int * 'a deep
                         
     and 'a deep = {
       fo : 'a chunk; fi : 'a chunk;
       mid : ('a chunk) chunkedseq;
       bi : 'a chunk; bo : 'a chunk;
     }

    let weight_of cs =
      match cs with
      | Shallow c -> Chunk.weight_of c
      | Deep (w, _) -> w

    let mk_deep d =
      let {fo; fi; mid; bi; bo} = d in
      let w =
        Chunk.weight_of fo + Chunk.weight_of fi +
          weight_of mid +
          Chunk.weight_of bo + Chunk.weight_of bi
      in
      Deep (w, d)

    let mk_shallow (c1, c2, c3, c4) =
      let c =
        if Chunk.weight_of c1 > 0 then
          c1
        else if Chunk.weight_of c2 > 0 then
          c2
        else if Chunk.weight_of c3 > 0 then
          c3
        else if Chunk.weight_of c4 > 0 then
          c4
        else
          failwith "bogus"
      in
      Shallow c

    type 'a weight_fn = 'a Chunk.weight_fn
                           
    let sigma = Chunk.sigma
                  
    let ec = Chunk.create

    let create = Shallow ec

    let empty cs =
      match cs with
      | Shallow c -> Chunk.empty c
      | _ -> false

    let rec push_front' : 'a. wf:('a weight_fn) -> ('a chunkedseq * 'a) -> 'a chunkedseq = fun ~wf (cs, x) ->
      match cs with
      | Shallow c ->
         if Chunk.full c then
           push_front' wf (mk_deep {fo=ec; fi=ec; mid=Shallow ec; bi=ec; bo=c}, x)
         else
           Shallow (Chunk.push_front wf (c, x))
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         if Chunk.full fo then
           if Chunk.empty fi then
             push_front' wf (mk_deep {fo=ec; fi=fo; mid=mid; bi=bi; bo=bo}, x)
           else
             let mid' = push_front' ~wf:(sigma wf) (mid, fi) in
             push_front' wf (mk_deep {fo=ec; fi=fo; mid=mid'; bi=bi; bo=bo}, x)
         else
           let fo' = Chunk.push_front wf (fo, x) in
           mk_deep {fo=fo'; fi=fi; mid=mid; bi=bi; bo=bo}

    let rec push_back' : 'a. wf:('a weight_fn) -> ('a chunkedseq * 'a) -> 'a chunkedseq = fun ~wf (cs, x) ->
      match cs with
      | Shallow c ->
         if Chunk.full c then
           push_back' wf (mk_deep {fo=ec; fi=ec; mid=Shallow ec; bi=ec; bo=c}, x)
         else
           Shallow (Chunk.push_back wf (c, x))
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         if Chunk.full bo then
           if Chunk.empty bi then
             push_back' wf (mk_deep {fo=fo; fi=fi; mid=mid; bi=bo; bo=ec}, x)
           else
             let mid' = push_back' ~wf:(sigma wf) (mid, bi) in
             push_back' wf (mk_deep {fo=fo; fi=fi; mid=mid'; bi=bo; bo=ec}, x)
         else
           let bo' = Chunk.push_back wf (bo, x) in
           mk_deep {fo=fo; fi=fi; mid=mid; bi=bi; bo=bo'}
                   
    let rec check : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq = fun ~wf cs ->
      match cs with
      | Shallow c -> Shallow c
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         let w = 
           Chunk.weight_of fo + Chunk.weight_of fi +
             weight_of mid +
             Chunk.weight_of bo + Chunk.weight_of bi
         in
         if w = 0 && not (empty mid) then
           let (mid', fo') = pop_front' ~wf:(sigma wf) mid in
           mk_deep {fo=fo'; fi=fi; mid=mid'; bi=bi; bo=bo}
         else if w <= 1 && empty mid then
           mk_shallow (fo, fi, bi, bo)
         else
           cs
             
    and mk_deep' : 'a. wf:('a weight_fn) -> 'a deep -> 'a chunkedseq = fun ~wf d ->
      match d with
      | {fo; fi; mid; bi; bo} ->
      let w = Chunk.weight_of fo + Chunk.weight_of fi +
                weight_of mid +
                Chunk.weight_of bi + Chunk.weight_of bo
      in
      Deep (w, d)

    and pop_front' : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq * 'a = fun ~wf cs ->
      match cs with
      | Shallow c ->
         let (c', x) = Chunk.pop_front wf c in
         (Shallow c', x)
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         if Chunk.empty fo then
           if not (Chunk.empty fi) then
             pop_front' wf (mk_deep' wf {fo=fi; fi=ec; mid=mid; bi=bi; bo=bo;})
           else if not (empty mid) then
             let (mid', c) = pop_front' ~wf:(sigma wf) mid in
             pop_front' wf (mk_deep' wf {fo=c; fi=fi; mid=mid'; bi=bi; bo=bo})
           else if not (Chunk.empty bi) then
             pop_front' wf (mk_deep' wf {fo=bo; fi=fi; mid=mid; bi=bi; bo=ec})
           else
             let (bo', x) = Chunk.pop_front wf bo in
             (mk_deep' wf {fo=fo; fi=fi; mid=mid; bi=bi; bo=bo'}, x)
         else
           let (fo', x) = Chunk.pop_front wf fo in
           (mk_deep' wf {fo=fo'; fi=fi; mid=mid; bi=bi; bo=bo}, x)

    and pop_back' : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq * 'a = fun ~wf cs ->
      match cs with
      | Shallow c ->
         let (c', x) = Chunk.pop_back wf c in
         (Shallow c', x)
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         if Chunk.empty bo then
           if not (Chunk.empty bi) then
             pop_back' wf (mk_deep' wf {fo=fo; fi=fi; mid=mid; bi=ec; bo=bi})
           else if not (empty mid) then
             let (mid', c) = pop_back' ~wf:(sigma wf) mid in
             pop_back' wf (mk_deep' wf {fo=fo; fi=fi; mid=mid'; bi=bi; bo=c})
           else if not (Chunk.empty bi) then
             pop_back' wf (mk_deep' wf {fo=ec; fi=fi; mid=mid; bi=bi; bo=fo})
           else
             let (fo', x) = Chunk.pop_back wf bo in
             (mk_deep' wf {fo=fo'; fi=fi; mid=mid; bi=bi; bo=bo}, x)
         else
           let (bo', x) = Chunk.pop_back wf bo in
           (mk_deep' wf {fo=fo; fi=fi; mid=mid; bi=bi; bo=bo'}, x)

    and push_buffer_back : 'a. ('a chunk weight_fn) -> ('a chunk chunkedseq * 'a chunk) -> 'a chunk chunkedseq = fun wf (cs, c) ->
      if Chunk.empty c then
	cs
      else if empty cs then
	Shallow (Chunk.push_back wf (Chunk.create, c))
      else
	let (cs', c') = pop_back' wf cs in
	if Chunk.size c + Chunk.size c' <= Chunk.k then
	  push_back' wf (cs', Chunk.concat wf (c', c))
	else
	  push_back' wf (cs, c)

    and push_buffer_front : 'a. 'a chunk weight_fn -> ('a chunk chunkedseq * 'a chunk) -> 'a chunk chunkedseq = fun wf (cs, c) ->
      if Chunk.empty c then
	cs
      else if empty cs then
	Shallow (Chunk.push_front wf (Chunk.create, c))
      else
	let (cs', c') = pop_front' wf cs in
	if Chunk.size c + Chunk.size c' <= Chunk.k then
	  push_front' wf (cs', Chunk.concat wf (c, c'))
	else
	  push_front' wf (cs, c)

    and transfer_contents_back : 'a. 'a weight_fn -> ('a chunkedseq * 'a chunk) -> 'a chunkedseq = fun wf (cs, c) ->
      if Chunk.empty c then
	cs
      else
	let (c', x) = Chunk.pop_front wf c in
	transfer_contents_back wf (push_back' wf (cs, x), c')

    and transfer_contents_front : 'a. 'a weight_fn -> ('a chunkedseq * 'a chunk) -> 'a chunkedseq = fun wf (cs, c) ->
      if Chunk.empty c then
	cs
      else
	let (c', x) = Chunk.pop_back wf c in
	transfer_contents_front wf (push_front' wf (cs, x), c')	  

    and concat' : 'a. wf:('a weight_fn) -> 'a chunkedseq * 'a chunkedseq -> 'a chunkedseq = fun ~wf (cs1, cs2) ->
      match (cs1, cs2) with
      | (Shallow c1, _) ->
         transfer_contents_front wf (cs2, c1)
      | (_, Shallow c2) ->
         transfer_contents_back wf (cs1, c2)
      | (Deep (_, {fo=fo1; fi=fi1; mid=mid1; bi=bi1; bo=bo1}),
         Deep (_, {fo=fo2; fi=fi2; mid=mid2; bi=bi2; bo=bo2})) ->
           let mid1' = push_buffer_back (sigma wf) (mid1, bi1) in
           let mid1'' = push_buffer_back (sigma wf) (mid1', bo1) in
           let mid2' = push_buffer_front (sigma wf) (mid2, fi2) in
           let mid2'' = push_buffer_front (sigma wf) (mid2', fo2) in
           if empty cs1 then
             cs2
           else if empty cs2 then
             cs1
           else
             let ((_, c1), (_, c2)) = (pop_back' (sigma wf) mid1', pop_front' (sigma wf) mid2'') in
             let (mid1''', mid2''') =
               if Chunk.weight_of c1 + Chunk.weight_of c2 <= Chunk.k then
		 let (mid1'', _) = pop_back' (sigma wf) mid1'' in
		 let (mid2'', _) = pop_front' (sigma wf) mid2'' in
		 let c' = Chunk.concat wf (c1, c2) in
		 (push_back' (sigma wf) (mid1'', c'), mid2'')
               else
		 (mid1'', mid2'')
             in
             let mid12 = concat' (sigma wf) (mid1''', mid2''') in
             mk_deep' wf {fo=fo1; fi=fi1; mid=mid12; bi=bi2; bo=bo2}

    and split' : 'a. wf:('a weight_fn) -> ('a chunkedseq * int) -> ('a chunkedseq * 'a * 'a chunkedseq) = fun ~wf (cs, i) ->
      match cs with
      | Shallow c ->
         let (c1, x, c2) = Chunk.split wf (c, i) in
         (Shallow c1, x, Shallow c2)
      | Deep (_, {fo; fi; mid; bi; bo}) ->
         let (wfo, wfi) = (Chunk.weight_of fo, Chunk.weight_of fi) in
         let wm = weight_of mid in
         let (wbi, wbo) = (Chunk.weight_of bi, Chunk.weight_of bo) in
         let (cs1, x, cs2) =
           if i <= wfo then
             let (fo1, x, fo2) = Chunk.split wf (fo, i) in
             let cs1 = mk_deep {fo=fo1; fi=ec; mid=Shallow ec; bi=ec; bo=ec} in
             let cs2 = mk_deep {fo=fo2; fi=ec; mid=mid; bi=bi; bo=bo} in
             (cs1, x, cs2)
           else if i <= wfo + wfi + wm then
             let j = i - wfo - wfi in
             let (mid1, c, mid2) = split' (sigma wf) (mid, j) in
             let (c1, x, c2) = Chunk.split wf (c, j - weight_of mid1) in
             let cs1 = mk_deep {fo=fo; fi=fi; mid=mid1; bi=ec; bo=c1} in
             let cs2 = mk_deep {fo=c2; fi=ec; mid=mid2; bi=bi; bo=bo} in
             (cs1, x, cs2)
           else if i <= wfo + wfi + wm + wbi then
             failwith ""
           else
             failwith ""

         in
         (check wf cs1, x, check wf cs2)
           
  end
