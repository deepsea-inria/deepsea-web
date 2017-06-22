

(**
  Structure is either empty or is a pointer to a nonempty
  imperative chunkedstack
*)

module Make (Stack : SeqSig.S)
= struct


type 'a t = 
  | S0
  | SStack of 'a Stack.t

let empty = S0

let is_empty s =
  match s with
  | S0 -> true
  | SStack r -> false

let push_back x s =
  match s with
  | S0 -> 
      let r = Stack.create 0 in
      Stack.push_back x r;
      SStack r
  | SStack r ->
      Stack.push_back x r;
      s

let pop_back s =
  match s with
  | S0 -> raise Not_found
  | SStack r ->
      let x = Stack.push_back r in
      if Stack.is_empty r 
        then (x, S0)
        else (x, SStack r)

let length s =
  match s with
  | S0 -> 0
  | SStack r -> Stack.length r

end