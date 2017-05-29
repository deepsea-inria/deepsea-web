
(** Representation of a purely-functional sequence as an immutable
    array, with copy-on-write.
    
    Implements PSegSig.S *)

type 'a t = 'a array

module PolymorphicEmptyArray : sig val empty : 'a t end = struct
  let empty = (Obj.magic [||])
end

let empty = 
  PolymorphicEmptyArray.empty

let length s =
   Array.length s

let is_empty s = 
   length s = 0

let front s =
   assert (length s > 0);
   s.(0)

let back s =
   let n = length s in
   assert (n > 0);
   s.(n-1)

(* linear-time *)
let push_front x s =
   let n = length s in
   let t = Array.make (n+1) x in
   Array.blit s 0 t 1 n;
   t

(* linear-time *)
let pop_front s =
   let n = length s in
   assert (n > 0);
   let x = s.(0) in
   let t = Array.make (n-1) x in
   Array.blit s 1 t 0 (n-1);
   t
   
(* linear-time *)
let push_back x s = 
   let n = length s in
   let t = Array.make (n+1) x in
   Array.blit s 0 t 0 n;
   t

(* linear-time *)
let pop_back s = 
   let n = length s in
   assert (n > 0);
   let x = s.(n-1) in
   let t = Array.make (n-1) x in
   Array.blit s 0 t 0 (n-1);
   t

(* linear-time *)
let append s1 s2 =
  Array.append s1 s2

(* linear-time *)
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
  Array.iter f s

let fold_left f i s =
  Array.fold_left f i s

let fold_right f s i =
  Array.fold_right f s i

let to_list s = 
   Array.to_list s

