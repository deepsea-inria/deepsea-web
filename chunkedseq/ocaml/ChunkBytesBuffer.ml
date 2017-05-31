
(** Representation of a ephemeral fixed-capacity chunks of bytes *)

module Make (Capacity : CapacitySig.S) = 
struct


let capacity = Capacity.capacity

let dummy_char = 'a' 

type t = {
  data : bytes;
  mutable size : int; }

let create () = 
  { data = Bytes.make capacity dummy_char;
    size = 0; }

let length s =
  s.size 

let is_empty s =
  s.size = 0

(* [create_of_bytes w o n] creates a chunk storing the bytes 
   from [w] starting at index [o] over a length [n] *)

let create_of_bytes w o n =
   assert (0 <= n && n <= capacity);
   let data = Bytes.make capacity dummy_char in
   Bytes.blit w o data 0 n;
   { data = data; size = n; }

(* [push_bytes w o n s] pushes into [s] the bytes from [w]
   starting at index [o] over a length [n] *)

let push_bytes_of w o n s =
   let new_size = s.size + n in
   assert (new_size <= capacity);
   Bytes.blit w o s.data s.size n;
   s.size <- new_size

(* [push_bytes w s] pushes all the bytes from [w] *)

let push_bytes w s =
  push_bytes_of w 0 (Bytes.length w) s

let front s =
   assert (length s > 0);
   Bytes.get s.data 0

let back s =
   assert (length s > 0);
   let i = s.size - 1 in
   Bytes.get s.data i

let push_back s =
  assert false

let pop_back s =
  assert false

(* linear time, always *)
let push_front x s = 
  assert false

(* linear time, always *)
let pop_front s = 
  assert false

let append s1 s2 =
  assert false

let split_at i s =
  assert false 

let iter f s =
   for i = 0 to (s.size - 1) do
      let x = Bytes.get s.data i in
      f x;
   done

let fold_left f a s =
   let acc = ref a in
   for i = 0 to (s.size - 1) do
      let x = Bytes.get s.data i in
      acc := f !acc x;
   done;
   !acc

let fold_right f s a =
   let acc = ref a in
   for i = s.size - 1 downto 0 do
      let x = Bytes.get s.data i in
      acc := f x !acc;
   done;
   !acc

let to_list s = 
   fold_right (fun x a -> x::a) s []

end
