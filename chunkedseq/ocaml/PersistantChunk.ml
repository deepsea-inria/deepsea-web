
(** Representation of a persistant fixed-capacity chunk,
    based on arrays, with optimization to save on the number of
    copy-on-write operations on push-back operations.

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

type 'a support = {
  data : 'a array; (* of size equal to capacity *)
  mutable max_size : int; }

(** Representation of a persistent chunk.
    The invariant is that the elements in the chunk are 
    those in the support array between the indices [head]
    inclusive and [head+size] exclusive. 
    We maintain: head+size <= support.max_size <= capacity *)

type 'a t = {
  support : 'a support;
  head : int;
  size : int }
  

(*--------------------------------------------------------------------------*)

module PolymorphicEmptyArray : sig val empty : 'a t end = struct
  (* cells from this array will never be accessed,
     so there is no need to allocate the cells *)
  let empty = (Obj.magic ([||]))
end

let default_support = 
  { data = PolymorphicEmptyArray.empty;
    max_size = capacity; } (* prevents updates to the support *)

let empty =   
  { support = default_support;
    head = 0;
    size = 0; }

let length s =
   s.size

let is_empty s = 
   length s = 0

let front s =
   assert (length s > 0);
   let i = s.head in
   s.support.data.(i)

let back s =
   assert (length s > 0);
   let i = s.head + s.size - 1 in
   s.support.data.(i)

let push_front x s =
   let m = s.support.max_size in
   let i = s.head + s.size in
   if i = m && m < capacity then begin
      s.support.max_size <- m+1;
      s.support.data.(i) <- x;
      { support = s.support;
        head = s.head;
        size = s.size + 1; }
   end else begin
     let snew = { data = Array.make s.default

   end

   let n = length s in
   let t = Array.make (n+1) x in
   Array.blit s 0 t 1 n;
   t



let pop_front s =
   let n = length s in
   assert (n > 0);
   let x = s.(0) in
   let t = Array.make (n-1) x in
   Array.blit s 1 t 0 (n-1);
   t
   
let push_back x s = 
   let n = length s in
   let t = Array.make (n+1) x in
   Array.blit s 0 t 0 n;
   t

let pop_back s = 
   let n = length s in
   assert (n > 0);
   let x = s.(n-1) in
   let t = Array.make (n-1) x in
   Array.blit s 0 t 0 (n-1);
   t

let append s1 s2 =
  Array.append s1 s2

let split_at i s =
   let n = length s in
   if n = 0 then (empty,s) else begin
      let x = s.(0) in
      let t1 = Array.make i x in
      Array.blit s 0 t1 0 i;
      let t2 = Array.make (n-i) x in
      Array.blit s i t2 0 (n-i);
      (t1,t2)
   end




let iter f s =
   for i = s.head to (s.head + s.size - 1) do
      let x = Array.get s.support.data i in
      f x;
   done

let fold_left f a q =
   let acc = ref a in
   for i = s.head to (s.head + s.size - 1) do
      let x = Array.get s.support.data i in
      acc := f !acc x;
   done
   !acc

let fold_right f q a =
   let acc = ref a in
   for i = s.head + s.size - 1 downto s.head do
      let x = Array.get s.support.data i in
      acc := f x !acc;
   done

let to_list s = 
   fold_right (fun x a -> x::a) s []

end