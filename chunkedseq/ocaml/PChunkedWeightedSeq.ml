module PChunkedWeightedSeq
  = struct
      
    type 'a chunk = 'a Chunk.chunk

    type weight = Chunk.weight
	  
    type 'a chunkedseq
      = Shallow of 'a chunk
      | Deep of weight * 'a deep
                         
     and 'a deep = {
       fo : 'a chunk;
       fi : 'a chunk;
       mid : ('a chunk) chunkedseq;
       bi : 'a chunk;
       bo : 'a chunk;
     }
                                
    let weight cs =
      match cs with
      | Shallow c ->
         Chunk.weight c
      | Deep (w, _) ->
         w

    let mk_deep d =
      let {fo; fi; mid; bi; bo} = d in
      let w =
        Chunk.weight fo + Chunk.weight fi +
          weight mid +
          Chunk.weight bo + Chunk.weight bi
      in
      Deep (w, d)

    let mk_shallow (c1, c2, c3, c4) =
      let c =
        if Chunk.weight c1 > 0 then
          c1
        else if Chunk.weight c2 > 0 then
          c2
        else if Chunk.weight c3 > 0 then
          c3
        else if Chunk.weight c4 > 0 then
          c4
        else
          failwith "PChunkedWeightedSeq.mk_shallow: bogus input"
      in
      Shallow c

    type 'a weight_fn = 'a Chunk.weight_fn
                           
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
            push_front' wf (mk_deep {fo=ec; fi=ec; mid=create; bi=ec; bo=c}, x)
          else
            Shallow (Chunk.push_front wf (c, x))
      | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
          if Chunk.full fo then
            if Chunk.empty fi then
              push_front' wf (mk_deep {d with fo=ec; fi=fo}, x)
            else
              let mid' = push_front' ~wf:(Chunk.weight) (mid, fi) in
              push_front' wf (mk_deep {d with fo=ec; fi=fo; mid=mid'}, x)
          else
            let fo' = Chunk.push_front wf (fo, x) in
            mk_deep {d with fo=fo'}

    let rec push_back' : 'a. wf:('a weight_fn) -> ('a chunkedseq * 'a) -> 'a chunkedseq = fun ~wf (cs, x) ->
      match cs with
      | Shallow c ->
          if Chunk.full c then
            push_back' wf (mk_deep {fo=c; fi=ec; mid=create; bi=ec; bo=ec}, x)
          else
            Shallow (Chunk.push_back wf (c, x))
      | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
          if Chunk.full bo then
            if Chunk.empty bi then
              push_back' wf (mk_deep {d with bi=bo; bo=ec}, x)
            else
              let mid' = push_back' ~wf:(Chunk.weight) (mid, bi) in
              push_back' wf (mk_deep {d with mid=mid'; bi=bo; bo=ec}, x)
          else
            let bo' = Chunk.push_back wf (bo, x) in
            mk_deep {d with bo=bo'}

    and check : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq = fun ~wf cs ->
      match cs with
      | Shallow c ->
	 assert false
      | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
          let w = 
            Chunk.weight fo + Chunk.weight fi +
              Chunk.weight bo + Chunk.weight bi
          in
          if w = 0 && not (empty mid) then
            let (mid', fo') = pop_front' ~wf:(Chunk.weight) mid in
            mk_deep {d with fo=fo'; mid=mid'}
          else if w = 1 && empty mid then
            mk_shallow (fo, fi, bi, bo)
          else if w = 0 && empty mid then
            create
          else
            cs

   and mk_deep' : 'a. wf:('a weight_fn) -> 'a deep -> 'a chunkedseq = fun ~wf d ->
      check wf (mk_deep d)

    and pop_front' : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq * 'a = fun ~wf cs ->
      match cs with
      | Shallow c ->
         let (c', x) = Chunk.pop_front wf c in
         (Shallow c', x)
      | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
         if Chunk.empty fo then
           if not (Chunk.empty fi) then
             pop_front' wf (mk_deep' wf {d with fo=fi; fi=ec;})
           else if not (empty mid) then
             let (mid', c) = pop_front' ~wf:(Chunk.weight) mid in
             pop_front' wf (mk_deep' wf {d with fo=c; mid=mid'})
           else if not (Chunk.empty bi) then
             pop_front' wf (mk_deep' wf {d with fo=bi; bi=ec})
           else
             let (bo', x) = Chunk.pop_front wf bo in
             (mk_deep' wf {d with bo=bo'}, x)
         else
           let (fo', x) = Chunk.pop_front wf fo in
           (mk_deep' wf {d with fo=fo'}, x)

    and pop_back' : 'a. wf:('a weight_fn) -> 'a chunkedseq -> 'a chunkedseq * 'a = fun ~wf cs ->
      match cs with
      | Shallow c ->
         let (c', x) = Chunk.pop_back wf c in
         (Shallow c', x)
      | Deep (_, ({fo; fi; mid; bi; bo} as d)) ->
         if Chunk.empty bo then
           if not (Chunk.empty bi) then
             pop_back' wf (mk_deep' wf {d with bi=ec; bo=bi})
           else if not (empty mid) then
             let (mid', c) = pop_back' ~wf:(Chunk.weight) mid in
             pop_back' wf (mk_deep' wf {d with mid=mid'; bo=c})
           else if not (Chunk.empty fi) then
             pop_back' wf (mk_deep' wf {d with fi=ec; bo=fi})
           else
             let (fo', x) = Chunk.pop_back wf fo in
             (mk_deep' wf {d with fo=fo'}, x)
         else
           let (bo', x) = Chunk.pop_back wf bo in
           (mk_deep' wf {d with bo=bo'}, x)

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
              failwith "PChunkedWeightedSeq.split: out of bounds"
          in
          (check wf cs1, x, check wf cs2)

    let rec fold_right : 'a 'b . ('a -> 'b -> 'b) -> 'a chunkedseq -> 'b -> 'b = fun f cs i ->
      match cs with
      | Shallow c ->
         Chunk.fold_right f c i
      | Deep (_, {fo; fi; mid; bi; bo}) ->
          Chunk.fold_right f fo (
            Chunk.fold_right f fi (
              fold_right (fun c i' -> 
                Chunk.fold_right f c i') mid (
                 Chunk.fold_right f bi (
                   Chunk.fold_right f bo i))))

    let list_of cs =
      fold_right (fun x y -> x :: y) cs []
      
  end
