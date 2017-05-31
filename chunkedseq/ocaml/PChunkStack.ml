
(** Representation of a persistent fixed-capacity chunk,
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
    those in the support array between the indices [0]
    inclusive and [size] exclusive. 
    We maintain: size <= support.max_size <= capacity *)

type 'a t = {
  support : 'a support;
  size : int }
  

(*--------------------------------------------------------------------------*)

module PolymorphicEmptySupport : sig val empty : 'a support end = struct
  (* cells from this array will never be accessed,
     so there is no need to allocate the cells *)
  let empty = (Obj.magic
    { data = [||];
      max_size = capacity; })
end

let empty =   
  { support = PolymorphicEmptySupport.empty;
    size = 0; }

let create_for size data =
   let support = { data = data;
                   max_size = size; } in
   { support = support;
     size = size; }

let length s =
   s.size

let is_empty s = 
   length s = 0

let front s =
   assert (length s > 0);
   s.support.data.(0)

let back s =
   assert (length s > 0);
   let i = s.size - 1 in
   s.support.data.(i)

(* constant time, unless a copy-on-write is needed *)
let push_back x s =
   let m = s.support.max_size in
   if s.size = m && m < capacity then begin
      (* exploit sharing *)
      s.support.max_size <- m + 1;
      s.support.data.(s.size) <- x;
      { support = s.support;
        size = s.size + 1; }
   end else begin
    (* copy-on-write *)
     assert (s.size < capacity);
     let new_size = s.size + 1 in
     let new_data = Array.make capacity x in
     (* redundant here: new_data.(s.size) <- x *)
     Array.blit s.support.data 0 new_data 0 s.size;
     create_for new_size new_data
   end

(* constant time, always, by exploiting sharing *)
let pop_back s =
  let i = s.size - 1 in
  let x = s.support.data.(i) in
  x, { support = s.support;
       size = s.size - 1; }

(* linear time, always *)
let push_front x s = 
   (* copy-on-write *)
   let new_size = s.size + 1 in
   let new_data = Array.make capacity x in
   (* redundant here: new_data.(0) <- x *)
   Array.blit s.support.data 0 new_data 1 s.size;
   create_for new_size new_data

(* constant time, always, by exploiting sharing *)
let pop_front s = 
  let x = s.support.data.(0) in
  x, { support = s.support;
       size = s.size - 1; }

(* biaised towards updating the support of s1 *)
let append s1 s2 =
  let new_size = s1.size + s2.size in
  assert (new_size <= capacity);
  let m1 = s1.support.max_size in
  let d1 = s1.support.data in
  let d2 = s2.support.data in
  if s1.size = m1 && m1 + s2.size <= capacity then begin
    (* exploit sharing *)
    s1.support.max_size <- m1 + s2.size;
    Array.blit d2 0 d1 s1.size s2.size;
    { support = s1.support;
      size = new_size; }
  end else begin
    (* copy-on-write *)
    let new_data = Array.make capacity d1.(0) in
    Array.blit d1 0 new_data 0 s1.size;
    Array.blit d2 0 new_data s1.size s2.size;
    create_for new_size new_data
  end

(* constant time, always *)
let split_at i s =
  assert false

let iter f s =
   for i = 0 to (s.size - 1) do
      let x = Array.get s.support.data i in
      f x;
   done

let fold_left f a s =
   let acc = ref a in
   for i = 0 to (s.size - 1) do
      let x = Array.get s.support.data i in
      acc := f !acc x;
   done;
   !acc

let fold_right f s a =
   let acc = ref a in
   for i = s.size - 1 downto 0 do
      let x = Array.get s.support.data i in
      acc := f x !acc;
   done;
   !acc

let to_list s = 
   fold_right (fun x a -> x::a) s []

end