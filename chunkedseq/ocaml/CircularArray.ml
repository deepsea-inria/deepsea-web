

(** Representation of polymorphic circular buffers *)

module Make (Capacity : CapacitySig.S) = 
struct

(*--------------------------------------------------------------------------*)

(** Aliases *)

let capacity = Capacity.capacity

(** Representation of a queue *)

type 'a t = {
  mutable default : 'a;
  mutable head : int;
  mutable size : int;
  mutable data : 'a array; }

(*--------------------------------------------------------------------------*)

(** Builds a new queue *)

let create d = 
  { default = d;
    head = 0;
    size = 0;
    data = Array.make capacity d; }

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

(** Read the element from the front (assumes non-empty queue) *)

let front q = 
   Array.get q.data q.head

(** Read the element from the back (assumes non-empty queue) *)

let back q = 
  let i = wrap_up (q.head + q.size - 1) in
  Array.get q.data i

(** Pop an element from the front (assumes non-empty queue) *)

let pop_front q = 
  let x = Array.get q.data q.head in
  (* for appropriate garbage collection, insert:  
     Array.seq q.data q.head q.default; *)
  q.head <- wrap_up (q.head + 1);
  q.size <- q.size - 1;
  x
  
(** Pop an element from the back (assumes non-empty queue) *)

let pop_back q = 
  q.size <- q.size - 1;
  let i = wrap_up (q.head + q.size) in
  let x = Array.get q.data i in
  (* for appropriate garbage collection, insert:  
     Array.seq q.data i q.default; *)
  x

(** Push an element to the front (assumes non-full queue) *)

let push_front x q =
  q.head <- wrap_down (q.head - 1);
  Array.set q.data q.head x;
  q.size <- q.size + 1

(** Push an element to the back (assumes non-full queue) *)

let push_back x q =
  let i = wrap_up (q.head + q.size) in
  Array.set q.data i x;
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
   copy_data_wrap_src_and_dst q1.data h1 q2.data h2 n;
  (* for appropriate garbage collection, insert code to fill
     default values in q1 on the removed range *)
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
  (* for appropriate garbage collection, insert code to fill
     default values in q1 on the removed range *)
   q1.size <- q1.size - n;
   q2.size <- q2.size + n;
   q1.head <- wrap_up (h1 + n)


(*--------------------------------------------------------------------------*)

(** Transfer all items from a buffer to the front of another buffer *)

let transfer_all_to_front q1 q2 =
   transfer_back_to_front q1.size q1 q2

(** Transfer all items from a buffer to the back of another buffer *)

let transfer_all_to_back q1 q2 =
   transfer_front_to_back q1.size q1 q2

(*--------------------------------------------------------------------------*)

(** Pop N elements from the front into an array *)

let popn_front_to_array n q = 
  if n < 0 || n > q.size 
     then invalid_arg "CircularArray.popn_front_to_array";
  if n = 0 then [||] else begin
     let h = q.head in
     let t = Array.make n q.data.(h) in
     copy_data_wrap_src q.data h t 0 n;
     (* for appropriate garbage collection, insert code to fill
        default values in q on the removed range *)
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
     (* for appropriate garbage collection, insert code to fill
        default values in q on the removed range *)
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

(*--------------------------------------------------------------------------*)

(* TODO: reimplement these functions using two loops each,
   for improved efficiency *)

(** Iter *)

let iter f q =
   let i = ref q.head in
   for k = 0 to pred q.size do
      f (Array.get q.data !i);
      incr i;
      if !i = capacity
         then i := 0;
   done

(** Fold-left *)

let fold_left f a q =
   let acc = ref a in
   let i = ref q.head in
   for k = 0 to pred q.size do
      acc := f !acc (Array.get q.data !i);
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
      acc := f (Array.get q.data !i) !acc;
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


(*--------------------------------------------------------------------------*)

end

