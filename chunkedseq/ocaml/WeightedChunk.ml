
  let k = 2

  type weight = int

  type 'a weight_fn = ('a -> weight)

  type 'a chunk = weight * 'a list

  let empty = (0, [])

  let size (_, xs) = List.length xs

  let sub ((_, xs), i) = List.nth xs i

  let back c = sub (c, size c - 1)

  let front (_, xs) = List.hd xs

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
    let sigma wf (_, xs) =
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
    let c1 = (sigma wf (0, xs1), xs1) in
    let c2 = (sigma wf (0, xs2), xs2) in
    (c1, x, c2)

  let weight (w, _) = w

  let is_empty c = (size c = 0)

  let is_full c = (size c = k)

  let fold_right : 'a 'b . ('a -> 'b -> 'b) -> 'a chunk -> 'b -> 'b = fun f (_, xs) x ->
    List.fold_right f xs x

