      val create : unit -> 'a Seq.t
   val create : unit -> t
   val create : unit -> 'a t


(** garbage *)

type 'a split_at_or_length = 
  | SplitAt of 'a list * 'a list
  | SplitAtFailed of int (* length *)

let rec list_split_at_or_length len n l =
   if n = 0 then ([],l) else
   match l with
   | [] -> SplitAtFailed len
   | x::r -> 
      let (a,b) = list_split_at (n-1) r in
      (x::a,b)

      let split_at i s =
  match list_split_at_or_length 0 i s.front with

  try 
    let (l1,l2) =  in
     ({ size = i; 
        front = l1;
        back = [] },
      { size = s.size - i; 
        front = l2;
        back = s.back } )
  with Not_found ->
    let (l1,l2) = list_split_at i s.back in
     ({ size = i; 
        front = s.front;
        back = s.back },
      { size = s.size - i; 
        data = l2;
        back = s.back } )

