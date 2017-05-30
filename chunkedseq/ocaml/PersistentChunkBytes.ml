
(** Representation of a persistant fixed-capacity chunk,
    based on arrays, with optimization to save on the number of
    copy-on-write operations on push-back operations.

    This version specializes the item type of PersistantChunk 
    to bytes.

    [Remark: we could also optimize push-front operations,
     but this would come at some cost.]

    [Remark: this code does not bother writing back dummy values
    after pop operations]
    
    Implements PSegSig.S *)

(** Representation of polymorphic circular buffers *)

module Make (Capacity : CapacitySig.S) = 
struct

(*--------------------------------------------------------------------------*)

(** Aliases *)

let capacity = Capacity.capacity

(** Data that may be shared by several chunks *)

type support = {
  data : bytes; (* of size equal to capacity *)
  mutable max_size : int; }

(** Representation of a persistent chunk.
    The invariant is that the elements in the chunk are 
    those in the support array between the indices [head]
    inclusive and [head+size] exclusive. 
    We maintain: head+size <= support.max_size <= capacity *)

type t = {
  support : support;
  head : int;
  size : int }
  

(*--------------------------------------------------------------------------*)

let dummy_char = 'a' 

let empty =   
  { support = { data = Bytes.empty; 
                max_size = capacity; };
    head = 0;
    size = 0; }

let create_for size data =
   { support = { data = data;
                 max_size = size; };
     head = 0;
     size = size; }

(* create_of_bytes w o n
   returns a chunk made of the n bytes of w starting at offset o,
   it is required that n <= capacity *)

let create_of_bytes w o n =
   let data = Bytes.make capacity dummy_char in
   Bytes.blit w o data 0 n;
   assert (n <= capacity);
   create_for n data

let length s =
   s.size

let is_empty s = 
   length s = 0

let front s =
   assert (length s > 0);
   let i = s.head in
   Bytes.get s.support.data i

let back s =
   assert (length s > 0);
   let i = s.head + s.size - 1 in
   Bytes.get s.support.data i

(* [push_bytes w o n s] pushes into [s] the bytes from [w]
   starting at index [o] over a length [n] *)

let push_bytes_of w o n s =
   let m = s.support.max_size in
   let i = s.head + s.size in
   if i = m && m + n <= capacity then begin
      (* exploit sharing *)
      s.support.max_size <- m + n;
      Bytes.blit w o s.support.data i n;
      { support = s.support;
        head = s.head;
        size = s.size + n; }
   end else begin
    (* copy-on-write *)
     assert (s.size + n <= capacity);
     let new_size = s.size + n in
     let new_data = Bytes.make capacity dummy_char in
     Bytes.blit s.support.data s.head new_data 0 s.size;
     Bytes.blit w o new_data s.size n;
     create_for new_size new_data
   end

(* [push_bytes w s] pushes all the bytes from [w] *)

let push_bytes w s =
  push_bytes_of w 0 (Bytes.length w) s

(* constant time, unless a copy-on-write is needed *)
let push_back x s =
   let m = s.support.max_size in
   let i = s.head + s.size in
   if i = m && m < capacity then begin
      (* exploit sharing *)
      s.support.max_size <- m+1;
      Bytes.set s.support.data i x;
      { support = s.support;
        head = s.head;
        size = s.size + 1; }
   end else begin
    (* copy-on-write *)
     assert (s.size < capacity);
     let new_size = s.size + 1 in
     let new_data = Bytes.make capacity x in
     (* redundant here: new_data.(s.size) <- x *)
     Bytes.blit s.support.data s.head new_data 0 s.size;
     create_for new_size new_data
   end

(* constant time, always, by exploiting sharing *)
let pop_back s =
  let i = s.head + s.size - 1 in
  let x = Bytes.get s.support.data i in
  x, { support = s.support;
       head = s.head;
       size = s.size - 1; }

(* linear time, always *)
let push_front x s = 
   (* copy-on-write *)
   let new_size = s.size + 1 in
   let new_data = Bytes.make capacity x in
   (* redundant here: new_data.(0) <- x *)
   Bytes.blit s.support.data s.head new_data 1 s.size;
   create_for new_size new_data

(* constant time, always, by exploiting sharing *)
let pop_front s = 
  let i = s.head in
  let x = Bytes.get s.support.data i in
  x, { support = s.support;
       head = s.head + 1;
       size = s.size - 1; }

(* biaised towards updating the support of s1 *)
let append s1 s2 =
  let new_size = s1.size + s2.size in
  assert (new_size <= capacity);
  let m1 = s1.support.max_size in
  let i1 = s1.head + s1.size in
  let d1 = s1.support.data in
  let d2 = s2.support.data in
  if i1 = m1 && m1 + s2.size <= capacity then begin
    (* exploit sharing *)
    s1.support.max_size <- m1 + s2.size;
    Bytes.blit d2 s2.head d1 i1 s2.size;
    { support = s1.support;
      head = s1.head;
      size = new_size; }
  end else begin
    (* copy-on-write *)
    let new_data = Bytes.make capacity dummy_char in
    Bytes.blit d1 s1.head new_data 0 s1.size;
    Bytes.blit d2 s2.head new_data s1.size s2.size;
    create_for new_size new_data
  end

(* constant time, always *)
let split_at i s =
  let s1 = { support = s.support;
             head = s.head;
             size = i; } in
  let s2 = { support = s.support;
             head = s.head + i;
             size = s.size - i; } in
  s1,s2

let iter f s =
   for i = s.head to (s.head + s.size - 1) do
      let x = Bytes.get s.support.data i in
      f x;
   done

let fold_left f a s =
   let acc = ref a in
   for i = s.head to (s.head + s.size - 1) do
      let x = Bytes.get s.support.data i in
      acc := f !acc x;
   done;
   !acc

let fold_right f s a =
   let acc = ref a in
   for i = s.head + s.size - 1 downto s.head do
      let x = Bytes.get s.support.data i in
      acc := f x !acc;
   done;
   !acc

let to_list s = 
   fold_right (fun x a -> x::a) s []

end
