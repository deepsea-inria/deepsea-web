

(*---------------------------------------------------------------*)
(** Signature of polymorphic ephemeral sequences *)

module type S = 
sig
   type 'a t 
   val create : 'a -> 'a t
   val create_def : 'a -> 'a t
   val is_empty : 'a t -> bool
   val length : 'a t -> int
   val back : 'a t -> 'a
   val front : 'a t -> 'a 
   val push_front :'a -> 'a t -> unit
   val pop_front : 'a t -> 'a
   val push_back : 'a -> 'a t -> unit
   val pop_back : 'a t -> 'a
   val append : 'a t -> 'a t -> unit
   val carve_back_at : int -> 'a t -> 'a * 'a t
   val iter : ('a -> unit) -> 'a t -> unit
   val fold_left : ('b -> 'a -> 'b) -> 'b -> 'a t -> 'b
   val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b
   val to_list : 'a t -> 'a list 
end


(*---------------------------------------------------------------*)
(** Sigature of fixed-capacity polymorphic ephemeral sequences *)

module type FixedCapacityS = 
sig
   include S
   val capacity : int
   val is_full : 'a t -> bool
end

