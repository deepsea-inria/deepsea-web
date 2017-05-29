
(** Representation of a purely-functional sequence as an immutable
    array, with copy-on-write.
    
    Implements PSegSig.S *)

(*

type 'a t = { 
   size : int;
   data : 'a list }

let empty = {
   size = 0;
   data = [] }

let is_empty s = 
   s.size = 0

let length s =
   s.size

let front s =
   match s.data with
   | [] -> raise Not_found
   | x::q -> x 
  
(* linear-time *)
let back s =
   let rec aux = function
      | [] -> assert false
      | [x] -> x
      | y::q -> aux q
      in
   aux s.data

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
      | [] -> assert false
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
   | [] -> assert false
   | x::r -> 
      let (a,b) = list_split_at (n-1) r in
      (x::a,b)

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

(** Auxiliary function to bulid a singleton list *)

let singleton x =
   { size = 1; data = [x] }

(** Auxiliary function to deconstruct a non-empty list *)

let head_and_tail s =
   match s.data with
   | [] -> assert false
   | x::q -> (x, { size = s.size - 1;
                   data = q })

let of_size_and_list n l = 
  { size = n; 
    data = l }

let of_list l =
   of_size_and_list (List.length l) l





(** Representation of fixed-size circular buffers.

    Author: Arthur Chargueraud *)

let get = Array.get
let set = Array.set 

(** The "Chunk" argument describes the size of the queue.
    Powers of two are preferable for more efficient modulo 
    operations (when inlining of functor arguments is performed). *)

module Make (Item : InhabType.S) (ChunkSize : Size.S) = 
struct

(*--------------------------------------------------------------------------*)

(** Aliases for the type of item and the capacity *)

type item = Item.t

let capacity = ChunkSize.value

(** Representation of a queue *)

type t = {
  mutable head : int;
  mutable size : int;
  mutable data : item array; }

(*--------------------------------------------------------------------------*)

(** Builds a new queue *)

let create () = 
  { head = 0;
    size = 0;
    data = Array.make capacity Item.inhab; }

(** Returns the size of the queue *)

let length q =
  q.size

(** Tests whether the queue is empty *)

let is_empty q =
  q.size = 0

(** Tests whether the queue is full *)

let is_full q =
  q.size = capacity

(** Auxiliary function to circle around indices that exceed capacity *)

let wrap_up i =
   if i < capacity then i else i - capacity

(** Auxiliary function to circle around indices that became negative *)

let wrap_down i =
   if i >= 0 then i else i + capacity

(*--------------------------------------------------------------------------*)

(** Pop an element from the front (assumes non-empty queue) *)

let pop_front q = 
  let x = get q.data q.head in
  q.head <- wrap_up (q.head + 1);
  q.size <- q.size - 1;
  x
  
(** Pop an element from the back (assumes non-empty queue) *)

let pop_back q = 
  q.size <- q.size - 1;
  let i = wrap_up (q.head + q.size) in
  get q.data i

(** Push an element to the front (assumes non-full queue) *)

let push_front x q =
  q.head <- wrap_down (q.head - 1);
  set q.data q.head x;
  q.size <- q.size + 1

(** Push an element to the back (assumes non-full queue) *)

let push_back x q =
  let i = wrap_up (q.head + q.size) in
  set q.data i x;
  q.size <- q.size + 1

(*--------------------------------------------------------------------------*)

let debug = false

(** Internal: copy n elements from an array t1 of size capacity,
    starting at index i1 and possibly wrapping around, into an 
    array t2 starting at index i2 and not wrapping around. *)

let copy_data_wrap_src t1 i1 t2 i2 n =
   if (debug && (i1 < 0 || i1 > capacity || i2 < 0 || i2 + n > capacity || n < 0))
      then failwith (Printf.sprintf "copy_data_wrap_src error: %d %d %d" i1 i2 n); 
   let j1 = i1 + n in
   if j1 <= capacity then begin
     Array.blit t1 i1 t2 i2 n
   end else begin
     let na = capacity - i1 in
     let i2' = wrap_up (i2 + na) in
     Array.blit t1 i1 t2 i2 na;
     Array.blit t1 0 t2 i2' (n - na);
   end

(** Internal: copy n elements from an array t1 starting at index i1
    and not wrapping around, into an array t2 of size capacity,
    starting at index i2 and possibly wrapping around. *)

let copy_data_wrap_dst t1 i1 t2 i2 n =
   if (debug && (i1 < 0 || i2 < 0 || i2 > capacity || i1 + n > capacity || n < 0))
      then failwith (Printf.sprintf "copy_data_wrap_dst error: %d %d %d" i1 i2 n);
   let j2 = i2 + n in
   if j2 <= capacity then begin
     Array.blit t1 i1 t2 i2 n;
   end else begin
     let na = capacity - i2 in
     let i1' = wrap_up (i1 + na) in
     Array.blit t1 i1 t2 i2 na;
     Array.blit t1 i1' t2 0 (n - na);
   end
   
(** Internal: copy n elements from an array t1 starting at index i1
    and possibly wrapping around, into an array t2 starting at index 
    i2 and possibly wrapping around. Both arrays are assumed to be
    of size capacity. *)

let copy_data_wrap_src_and_dst t1 i1 t2 i2 n =
   if (debug && (i1 < 0 || i1 > capacity || i2 > capacity || i2 < 0 || n < 0))
      then failwith (Printf.sprintf "copy_data_wrap_src_and_dst error: %d %d %d" i1 i2 n);
   let j1 = i1 + n in
   if j1 <= capacity then begin
      copy_data_wrap_dst t1 i1 t2 i2 n
   end else begin
     let na = capacity - i1 in
     let i2' = wrap_up (i2 + na) in
     copy_data_wrap_dst t1 i1 t2 i2 na;
     copy_data_wrap_dst t1 0 t2 i2' (n - na);
   end

(*--------------------------------------------------------------------------*)

(** Transfer N items from the back of a buffer to the front of another buffer *)

let transfer_back_to_front n q1 q2 =
   if n < 0 || n > q1.size || n + q2.size > capacity 
      then invalid_arg "CircularArray.transfer_back_to_front";
   let h1 = wrap_down (wrap_up (q1.head + q1.size) - n) in
   let h2 = wrap_down (q2.head - n) in
   (*TODO: hide Printf.printf "transfer h1=%d h2=%d n=%d s1=%d s2=%d\n" h1 h2 n q1.size q2.size;*)
   copy_data_wrap_src_and_dst q1.data h1 q2.data h2 n;
   q1.size <- q1.size - n;
   q2.size <- q2.size + n;
   q2.head <- h2

(** Transfer N items from the front of a buffer to the back of another buffer *)

let transfer_front_to_back n q1 q2 =
   if n < 0 || n > q1.size || n + q2.size > capacity 
      then invalid_arg "CircularArray.transfer_front_to_back";
   let h1 = q1.head in
   let h2 = wrap_up (q2.head + q2.size) in
   copy_data_wrap_src_and_dst q1.data h1 q2.data h2 n;
   q1.size <- q1.size - n;
   q2.size <- q2.size + n;
   q1.head <- wrap_up (h1 + n)

(*--------------------------------------------------------------------------*)

(** Pop N elements from the front into an array *)

let popn_front_to_array n q = 
  if n < 0 || n > q.size 
     then invalid_arg "CircularArray.popn_front_to_array";
  if n = 0 then [||] else begin
     let h = q.head in
     let t = Array.make n q.data.(h) in
     copy_data_wrap_src q.data h t 0 n;
     q.size <- q.size - n;
     q.head <- wrap_up (h + n);
     t
  end

(** Pop N elements from the back into an array *)

let popn_back_to_array n q = 
  if n < 0 || n > q.size then invalid_arg "CircularArray.popn_back_to_array";
  if n = 0 then [||] else begin
     let h = wrap_down (wrap_up (q.head + q.size) - n) in
     let t = Array.make n q.data.(h) in
     copy_data_wrap_src q.data h t 0 n;
     q.size <- q.size - n;
     t
  end

(** Push N elements to the front, taking them from an array *)

let pushn_front_from_array n t q =
  if n < 0 || n + q.size > capacity then invalid_arg "CircularArray.pushn_front_from_array";
  let h = wrap_down (q.head - n) in
  copy_data_wrap_dst t 0 q.data h n;
  q.head <- h;
  q.size <- q.size + n

(** Push N elements to the back, taking them from an array *)

let pushn_back_from_array n t q =
  if n < 0 || n + q.size > capacity then invalid_arg "CircularArray.pushn_back_from_array";
  let h = wrap_up (q.head + q.size) in
  copy_data_wrap_dst t 0 q.data h n;
  q.size <- q.size + n

(** Push N elements into the buffer assumed to be empty,
    taking items from an array. This function is an optimization
    of pushn_front_from_array and pushn_back_from_array *)

let pushn_in_empty_from_array n t q =
  if q.size <> 0 || n > capacity then invalid_arg "CircularArray.pushn_in_empty_from_array";
  let h = 0 in
  Array.blit t 0 q.data h n;
  q.head <- h;
  q.size <- n

(*--------------------------------------------------------------------------*)

(** Iter *)

let iter f q =
   let i = ref q.head in
   for k = 0 to pred q.size do
      f (get q.data !i);
      incr i;
      if !i = capacity
         then i := 0;
   done

(** Fold-left *)

let fold_left f a q =
   let acc = ref a in
   let i = ref q.head in
   for k = 0 to pred q.size do
      acc := f !acc (get q.data !i);
      incr i;
      if !i = capacity
         then i := 0;
   done;
   !acc

(** Fold-right *)

let fold_right f q a =
   let acc = ref a in
   let i = ref (wrap_down (wrap_up (q.head + q.size) - 1)) in
   for k = 0 to pred q.size do
      acc := f (get q.data !i) !acc;
      decr i;
      if !i = -1;
         then i := capacity-1;
   done;
   !acc

(** Conversions with lists *)

(* LATER: let of_list l =  assert (List.length l < capacity) *)

let to_list q =
   fold_right (fun x acc -> x::acc) q []

(*--------------------------------------------------------------------------*)

(** Random access *)

let get q i = 
   q.data.(wrap_up (q.head + i))

let set q i v =
   q.data.(wrap_up (q.head + i)) <- v

end

*)