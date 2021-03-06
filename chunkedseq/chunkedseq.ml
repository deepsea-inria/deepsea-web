(* 
To compile:
$ ocamlc -rectypes unix.cma chunkedseq.ml

To debug:
$ ocamlc -rectypes unix.cma -g chunkedseq.ml
$ ocamldebug a.out

*)

module ChunkedseqSpec =
  struct

    let create = []
    
    let size = List.length

    let sub (xs, i) = List.nth xs i

    let push_back (xs, x) = List.append xs [x]

    let push_front (xs, x) = x :: xs

    let pop_back xs =
      match List.rev xs with
      | x :: sx ->
         (List.rev sx, x)
      | [] ->
         failwith "ChunkedseqSpec.pop_back: bogus input"

    let pop_front xs =
      match xs with
      | x :: xs ->
         (xs, x)
      | [] ->
         failwith "ChunkedseqSpec.pop_front: bogus input"

    let concat (xs1, xs2) = List.append xs1 xs2

    let split (xs, i) =
      let rec f (sx, xs, i) =
        match xs with
        | x :: xs' ->
            if i = 0 then
              (List.rev sx, x, xs')
            else
              f (x :: sx, xs', i - 1)
        | [] ->
           failwith "ChunkedseqSpec.split: bogus input"
      in
      f ([], xs, i)
        
  end

module Chunk =
  struct

    let k = 2

    type weight = int

    type 'a weight_fn = ('a -> weight)

    type 'a chunk = weight * 'a list

    let create = (0, [])
                      
    let size (_, xs) = List.length xs
                 
    let sub ((_, xs), i) = List.nth xs i

    let push_back wf ((w, xs), x) = (w + wf x, List.append xs [x])
                                      
    let push_front wf ((w, xs), x) = (w + wf x, x :: xs)

    let pop_back wf (w, xs) =
      match List.rev xs with
      | x :: sx' -> ((w - wf x, List.rev sx'), x)
      | _ -> failwith "Chunk.pop_back: bogus input"

    let pop_front wf (w, xs) =
      match xs with
      | x :: xs' -> ((w - wf x, xs'), x)
      | _ -> failwith "Chunk.pop_front: bogus input"

    let concat _ ((w1, xs1), (w2, xs2)) = (w1 + w2, List.append xs1 xs2)
        
    let split : 'a. ('a weight_fn) -> ('a chunk * weight) -> ('a chunk * 'a * 'a chunk) = fun wf ((_, xs), i) ->
      let sigma xs =
        let sum = List.fold_left (fun x y -> x + y) 0 in
        sum (List.map wf xs)
      in
      let rec f (sx, xs, w) =
        match xs with
        | x :: xs' ->
            let w' = w + (wf x) in
            if w' > i then
              (List.rev sx, x, xs')
            else
              f (x :: sx, xs', w')
        | [] ->
            failwith "Chunk.split: bogus input"
      in
      let (xs1, x, xs2) = f([], xs, 0) in
      let c1 = (sigma xs1, xs1) in
      let c2 = (sigma xs2, xs2) in
      (c1, x, c2)

    let weight (w, _) = w

    let empty c = (size c = 0)

    let full c = (size c = k)

    let fold_right : 'a 'b . ('a -> 'b -> 'b) -> 'a chunk -> 'b -> 'b = fun f (_, xs) x ->
      List.fold_right f xs x
                                                 
  end

module Chunkedseq =
  struct

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
          failwith "Chunkedseq.mk_shallow: bogus input"
      in
      Shallow c

    type 'a weight_fn = 'a Chunk.weight_fn
                           
    let ec = Chunk.create

    let create = Shallow ec

    let empty cs =
      match cs with
      | Shallow c -> Chunk.empty c
      | _ -> false

    let unit_weight_fn : 'a weight_fn = fun _ -> 1

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

    and push_front  : 'a. ('a chunkedseq * 'a) -> 'a chunkedseq = fun (cs, x) ->
      push_front' unit_weight_fn (cs, x)
	      
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

    and push_back  : 'a. ('a chunkedseq * 'a) -> 'a chunkedseq = fun (cs, x) ->
      push_back' unit_weight_fn (cs, x)

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

    and pop_front : 'a. 'a chunkedseq -> 'a chunkedseq * 'a = fun cs ->
      pop_front' unit_weight_fn cs

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

    and pop_back : 'a. 'a chunkedseq -> 'a chunkedseq * 'a = fun cs ->
      pop_back' unit_weight_fn cs

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
                 if Chunk.size c1 + Chunk.size c2 <= Chunk.k then
                   let c' = Chunk.concat wf (c1, c2) in
                   (push_back' Chunk.weight (mid1''', c'), mid2''')
                 else
                   (mid1'', mid2'')
             in
             let mid12 = concat' Chunk.weight (mid1''', mid2''') in
             mk_deep' wf {fo=fo1; fi=fi1; mid=mid12; bi=bi2; bo=bo2}
                      
    and concat : 'a chunkedseq * 'a chunkedseq -> 'a chunkedseq = fun (cs1, cs2) ->
      concat' unit_weight_fn (cs1, cs2)
      
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
              let j = i - wfo - wfi - wm in
	            let (bi1, x, bi2) = Chunk.split wf (bi, j) in
	            let cs1 = mk_deep {d with bi=ec; bo=bi1} in
	            let cs2 = mk_deep {d with fo=bi2; fi=ec; mid=create; bi=ec} in
	            (cs1, x, cs2)
            else if i < wfo + wfi + wm + wbi + wbo then
              let j = i - wfo - wfi - wm - wbi in
	            let (bo1, x, bo2) = Chunk.split wf (bo, j) in
	            let cs1 = mk_deep {d with bo=bo1} in
	            let cs2 = mk_deep {fo=bo2; fi=ec; mid=create; bi=ec; bo=ec} in
	            (cs1, x, cs2)
	          else
              failwith "Chunkedseq.split: out of bounds"
          in
          (check wf cs1, x, check wf cs2)

    and split : 'a. ('a chunkedseq * int) -> ('a chunkedseq * 'a * 'a chunkedseq) = fun (cs, i) ->
      split' unit_weight_fn (cs, i)

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
   
module ChunkedseqTest =
  struct

   let _ = Random.init 1495380101
   let _ =
     let v = truncate (Unix.time ()) in
     Random.init v  
   
    type item = int

    type orientation = End_front | End_back

    type trace =
      | Trace_nil
      | Trace_push of orientation * item * trace
      | Trace_pop of orientation * trace
      | Trace_split_concat of int * trace * trace

    let random_item () = Random.int 1024

    let random_orientation () =
      if Random.int 2 = 0 then End_front else End_back

    let rec gen_trace n d =
      if n = 0 then
	      Trace_nil
      else if n >= 1 && Random.int (d + 3) = 0 then
	      let i = Random.int n in
	      let t1 = gen_trace i (d + 1) in
	      let t2 = gen_trace (n - i - 1) (d + 1) in
	      Trace_split_concat (i, t1, t2)
      else if (Random.int (2 + (1 lsl n))) < 3 then
	      let e = random_orientation () in
	      let x = random_item () in
	      let t = gen_trace (n + 1) d in
	      Trace_push (e, x, t)
      else
	      let e = random_orientation () in
	      let t = gen_trace (n - 1) d in
	      Trace_pop (e, t)
          
    let string_of_orientation e =
      match e with
      | End_front -> "F"
      | End_back -> "B"

    let print_trace t =
      let rec pt : trace -> string -> bool -> unit = fun t p s -> (
        if not (t = Trace_nil) then Printf.printf "%s%s" p (if s then "└── " else "├── ") else ();
        match t with 
        | Trace_nil ->
	          ()
        | Trace_push (e, x, t) ->
	          (Printf.printf "+%s[%d]\n" (string_of_orientation e) x;
	           pt t (p ^ (if s then "    " else "│   ")) true)
        | Trace_pop (e, t) ->
	          (Printf.printf "-%s[]\n" (string_of_orientation e);
	           pt t (p ^ (if s then "    " else "│   ")) true)
        | Trace_split_concat (i, t1, t2) ->
	          (Printf.printf "*%d\n" i;
	           pt t1 (p ^ (if s then "    " else "│   ")) false;
	           pt t2 (p ^ (if s then "    " else "│   ")) true))
      in
      pt t "" true
        
    let print_list sep print_item xs =
      let rec pl sep print_item xs =
        match xs with
        | [] ->
           ()
        | [x] ->
           print_item x
        | x :: xs -> (
          print_item x;
          Printf.printf "%s" sep;
          pl sep print_item xs)
      in
      (Printf.printf "["; pl sep print_item xs; Printf.printf "]")
                 
    type 'a list_compare_res =
      | Lists_equal
      | Lists_item_mismatch of int * 'a * 'a (* position of mismatch, 
                                              * and positions in first and second lists, 
                                              * respectively *)
      | Lists_unequal_lengths of int * int   (* length of first list, length of second *)

    let compare_lists (xs, ys) =
      let (n1, n2) = (List.length xs, List.length ys) in
      if n1 <> n2 then
        Lists_unequal_lengths (n1, n2)
      else
        let rec f (i, xs, ys) =
          match (xs, ys) with
          | ([], []) ->
             Lists_equal
          | (x :: xs, y :: ys) ->
             if x <> y then
               Lists_item_mismatch (i, x, y)
             else
               f (i + 1, xs, ys)
          | _ ->
             failwith "impossible"
        in
        f (0, xs, ys)

    let print_chunkedseq cs = print_list "," (Printf.printf "%d") (Chunkedseq.list_of cs)
    
    let check t0 = 
      let ok' r s =
        (match compare_lists (r, s) with
         | Lists_equal ->
            ()
         | Lists_item_mismatch (i, x, y) -> (
           let s = Printf.sprintf "item mismatch at %d with x=%d and y=%d\n" i x y in
           failwith s)
         | Lists_unequal_lengths (nr, ns) -> (
           let s = Printf.sprintf "unequal lengths |r|=%d and |s|=%d\n" nr ns in
           failwith s))
      in
      let ok r s = ok' r (Chunkedseq.list_of s) in
      let rec chk t r s = (
        ok r s;
        (match t with
         | Trace_nil ->
            (r, s)
         | Trace_push (End_front, x, t') ->
            let r' = ChunkedseqSpec.push_front (r, x) in
            let s' = Chunkedseq.push_front (s, x) in
            chk t' r' s'
         | Trace_push (End_back, x, t') ->
            let r' = ChunkedseqSpec.push_back (r, x) in
            let s' = Chunkedseq.push_back (s, x) in
            chk t' r' s'
         | Trace_pop (End_front, t') ->
            let (r', _) = ChunkedseqSpec.pop_front r in
            let (s', _) = Chunkedseq.pop_front s in
            chk t' r' s'
         | Trace_pop (End_back, t') ->
            let (r', _) = ChunkedseqSpec.pop_back r in
            let (s', _) = Chunkedseq.pop_back s in
            chk t' r' s'
         | Trace_split_concat (i, t1, t2) ->
            let (r1, x, r2) = ChunkedseqSpec.split (r, i) in
            let (s1, y, s2) = Chunkedseq.split (s, i) in
            let _ = ok r1 s1 in
            let _ = ok r2 s2 in
            let _ = ok' [x] [y] in
            let (r1', s1') = chk t1 r1 s1 in
            let (r2', s2') = chk t2 r2 s2 in
            let _ = ok r1' s1' in
            let _ = ok r2' s2' in
            let r' = ChunkedseqSpec.concat (r1', r2') in
            let s' = Chunkedseq.concat (s1', s2') in
            let _ = ok r' s' in
            (r', s')))
      in
      chk t0 ChunkedseqSpec.create Chunkedseq.create

   let rec check_loop n =
     if n <= 0 then
       ()
     else
       let t0 = Trace_push (random_orientation (), random_item (), gen_trace 1 1) in
       let _ = check t0 in
       check_loop (n - 1)
   
   let _ = check_loop 50000
    
  end
