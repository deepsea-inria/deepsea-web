
(** Representation of double-ended sequences as a triple made of
    two lists, one in each direction, and the sum of their size. 
    
    Implements PSegSig.S *)

type 'a t = { 
   size : int;
   front : 'a list;
   back : 'a list }

let empty = {
   size = 0;
   front = [];
   back = [] }

let is_empty s = 
   s.size = 0

let length s =
   s.size

(* auxiliary function *)
let rec list_last l = 
  match l with
  | [] -> raise Not_found
  | [x] -> x
  | x::q -> list_last q

(* worst-case linear-time *)
let front s =
   match s.front with
   | [] -> list_last s.back
   | x::q -> x 
  
(* worst-case linear-time *)
let back s =
   match s.back with
   | [] -> list_last s.front
   | x::q -> x 

let push_front x s =
   { size = s.size + 1;
     front = x::s.front;
     back = s.back }

(* worst-case linear-time *)
let pop_front s =
   match s.front with
   | [] -> 
      begin match List.rev s.back with
      | [] -> raise Not_found
      | x::q -> x, { size = s.size - 1;
                     front = q;
                     back = [] }
      end
   | x::q -> x, { size = s.size - 1;
                  front = q;
                  back = s.back } 
   
let push_back x s = 
   { size = s.size + 1;
     front = s.front;
     back = x::s.back }

(* worst-case linear-time *)
let pop_back s =
   match s.back with
   | [] -> 
      begin match List.rev s.front with
      | [] -> raise Not_found
      | x::q -> x, { size = s.size - 1;
                     front = [];
                     back = q }
      end
   | x::q -> x, { size = s.size - 1;
                  front = s.front;
                  back = q } 

(* linear-time, non-tail rec, 
   biaised to the front *)
let append s1 s2 =
  { size = s1.size + s2.size;
    front = s1.front @ (List.rev_append s1.back s2.front);
    back = s2.back }

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
  let nback = List.length s.back in 
  let nfront = s.size - nback in
  if i <= nfront then begin
     let (l1,l2) = list_split_at i s.front in
     ({ size = i; 
        front = l1;
        back = [] },
      { size = s.size - i; 
        front = l2;
        back = s.back } )
  end else begin 
    let j = nback - (i - nfront) in
    let (l1,l2) = list_split_at j s.back in
     ({ size = i; 
        front = s.front;
        back = l2 },
      { size = s.size - i; 
        front = [];
        back = l1 } )
  end

let iter f s =
  List.iter f s.front;
  List.iter f s.back

let fold_left f i s =
  let i = List.fold_left f i s.front in
  List.fold_left f i s.back

let fold_right f s i =
  List.fold_right f s.front 
    (List.fold_right f s.back i)

let to_list s = 
   s.front @ List.rev s.back

(* constant time *)
let rev s =
   { size = s.size;
     front = s.back;
     back = s.front }

