(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Jean-Christophe Filliatre                               *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

(** updated by Arthur Charguéraud to match signatures *)


type 'a t = {
  default: 'a;
  mutable size: int;
  mutable data: 'a array; (* 0 <= size <= Array.length data *)
}

let make n d =
  if n < 0 || n > Sys.max_array_length then invalid_arg "Vector.make";
  { default = d; size = n; data = Array.make n d; }

let create d =
  make 0 d

(*
let init n d f =
  if n < 0 || n > Sys.max_array_length then invalid_arg "Vector.init";
  { default = d; size = n; data = Array.init n f; }
*)

let length a =
  a.size

(*
let get a i =
  if i < 0 || i >= a.size then invalid_arg "Vector.get";
  Array.Array.get a.data i

let set a i v =
  if i < 0 || i >= a.size then invalid_arg "Vector.set";
  Array.Array.set a.data i v
*)

let resize a s =
  if s < 0 then invalid_arg "Vector.resize";
  let n = Array.length a.data in
  if s <= a.size then
    (* shrink *)
    if 4 * s < n then (* reallocate into a smaller array *)
      a.data <- Array.sub a.data 0 s
    else
      Array.fill a.data s (a.size - s) a.default
  else begin
    (* grow *)
    if s > n then begin (* reallocate into a larger array *)
      if s > Sys.max_array_length then invalid_arg "Vector.resize: cannot grow";
      let n' = min (max (2 * n) s) Sys.max_array_length in
      let a' = Array.make n' a.default in
      Array.blit a.data 0 a' 0 a.size;
      a.data <- a'
    end
  end;
  a.size <- s

(** stack interface *)

let is_empty a =
  length a = 0

(*
let clear a =
  resize a 0
*)

let push_back v a =
  let n = a.size in
  resize a (n+1);
  Array.set a.data n v

let pop_back a =
  let n = length a - 1 in
  if n < 0 then raise Not_found;
  let r = Array.get a.data n in
  resize a n;
  r

let push_front a v =
  assert false

let pop_front a v =
  assert false

let append a1 a2 =
  assert false
  (*
  let n1 = length a1 in
  let n2 = length a2 in
  resize a1 (n1 + n2);
  for i = 0 to n2 - 1 do Array.set a1 (n1 + i) (Array.get a2 i) done
  *)

let iter f a =
  for i = 0 to length a - 1 do 
    f (Array.get a.data i)
  done

let fold_left f x a =
  let r = ref x in
  for i = 0 to length a - 1 do 
    r := f !r (Array.get a.data i) 
  done;
  !r

let fold_right f a x =
  let r = ref x in
  for i = length a - 1 downto 0 do
    r := f (Array.get a.data i) !r 
  done;
  !r

let to_list s = 
   fold_right (fun x a -> x::a) s []
