(** Wrapper for pure lists; the "back" is the head of the list *)

type 'a t = 'a list

let empty = 
  []

let is_empty s =
  s = []

let push_back x s = 
  x::s

let length s =
  List.length s

let pop_back s = 
  match s with
  | [] -> raise Not_found
  | a::q -> (a,q)

let pop_front s = (* warning: linear-time, but no stack explosion *)
  (* todo: use a more clever technique *)
  let r = Shared.list_rev_notrec s in
  let (x,r') = pop_back r in
  (x, Shared.list_rev_notrec r)

let append s1 s2 = (* warning: linear-time, but no stack explosion *)
  let t1 = ref (Shared.list_rev_notrec s1) in
  let t2 = ref s2 in
  while !t1 <> [] do
     let (x,q) = pop_front !t1 in
     t1 := q;
     t2 := x::!t2;
  done;
  !t2

let push_front x s = (* warning: linear-time, but no stack explosion *)
  append s [x]

let split_at i s = (* warning: linear-time, but no stack explosion *)
  let t = ref s in
  let r = ref [] in
  let k = ref i in
  while !k > 0 do
     let (x,q) = pop_front !t in
     t := q;
     r := x::!r;
     decr k;
  done;
  (Shared.list_rev_notrec !r, !t)

let iter = List.iter

let fold_left = List.fold_left

let fold_right = List.fold_right

let to_list s = 
  s

let back s = 
  match s with
  | [] -> raise Not_found
  | a::q -> a

let front s =
  assert false (* TODO *)

