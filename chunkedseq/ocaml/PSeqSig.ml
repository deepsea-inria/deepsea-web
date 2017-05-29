
(*---------------------------------------------------------------*)
(** Signature of polymorphic pure sequences *)

module type S = 
sig 
   type 'a t
   val empty : 'a t
   val is_empty : 'a t -> bool
   val length : 'a t -> int
   val front : 'a t -> 'a
   val back : 'a t -> 'a
   val push_front : 'a -> 'a t -> 'a t
   val pop_front : 'a t -> 'a * 'a t
   val push_back : 'a -> 'a t -> 'a t
   val pop_back : 'a t -> 'a * 'a t
   val append : 'a t -> 'a t -> 'a t
   val split_at : int -> 'a t -> 'a t * 'a t
   val iter : ('a -> unit) -> 'a t -> unit
   val fold_left : ('b -> 'a -> 'b) -> 'b -> 'a t -> 'b
   val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b
   val to_list : 'a t -> 'a list
 end

