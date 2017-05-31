(** This file implements a fixed-capacity stack as a record
    pairing an array and an integer to keep track of the size.
    
    Note: this implementation does not write back default values. *)


type 'a t = {
  data : 'a array;
  mutable size : int; }

let make capacity d = 
  { data = Array.make capacity d;
    size = 0; }

let length s =
  s.size 

let is_empty s =
  s.size = 0

let push_back x s = 
  let n = s.size in
  s.data.(n) <- x;
  s.size <- n + 1

let pop_back s = 
  let n = s.size - 1 in
  let x = s.data.(n) in
  s.size <- n;
  x

let to_list s =
  let acc = ref [] in
  for i = s.size - 1 downto 0 do
    acc := s.data.(i) :: !acc;
  done;
  !acc
