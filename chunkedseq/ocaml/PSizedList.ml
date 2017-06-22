
(** Representation of single-ended sequences as a pair of
    a list and its size. 
    
    Implements PSegSig.S *)

type 'a t = { 
   size : int;
   data : 'a list }

let empty = {
   size = 0;
   data = [] }

let create () =
  empty

let is_empty s = 
   s.size = 0

let length s =
   s.size

let front s =
   match s.data with
   | [] -> raise Not_found
   | x::q -> x 
 
(* auxiliary function *)
let rec list_last l = 
  match l with
  | [] -> raise Not_found
  | [x] -> x
  | x::q -> list_last q

(* linear-time *)
let back s =
   list_last s.data

let push_front x s =
   { size = s.size + 1;
     data = x::s.data }

let pop_front s =
   match s.data with
   | [] -> raise Not_found
   | x::q -> x, { size = s.size - 1;
                  data = q } 
   
(* linear-time *)
let push_back x s = 
  { size = s.size + 1;
    data = s.data @ [x] }

(* linear-time *)
let pop_back s = 
   let rec aux = function
      | [] -> raise Not_found
      | [x] -> (x,[])
      | y::q -> 
         let (x,r) = aux q in
         (x, y::r)
      in
   let (x,r) = aux s.data in
   x, { size = s.size - 1; data = r }

(* linear-time, non-tail rec *)
let append s1 s2 =
  { size = s1.size + s2.size;
    data = s1.data @ s2.data; }

(* non-tail rec version *)
let rec list_split_at n l =
   if n = 0 then ([],l) else
   match l with
   | [] -> raise Not_found
   | x::r -> 
      let (a,b) = list_split_at (n-1) r in
      (x::a,b)

(* linear time *)
let split_at i s =
   let (l1,l2) = list_split_at i s.data in
   ({ size = i; 
      data = l1},
    { size = s.size - i; 
      data = l2} )

(* alternative: linear-time, constant-size stack  
let split_at i s =
   let t = ref s in
   let r = ref [] in
   let k = ref i in
   while !k > 0 do
      let (x,q) = pop_front !t in
      t := q;
      r := x::!r;
      decr k;
   done;
   ({ size = i; data = list_rev_notrec !r},
    { size = s.size - i; data = !t))
*) 

let iter f s =
  List.iter f s.data

let fold_left f i s =
  List.fold_left f i s.data

let fold_right f s i =
  List.fold_right f s.data i

let to_list s = 
   s.data

let rev s =
   { size = s.size;
     data = List.rev s.data }
