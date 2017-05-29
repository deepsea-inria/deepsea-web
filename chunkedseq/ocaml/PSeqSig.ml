
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


(*---------------------------------------------------------------*)
(** Signature of pure sequences, for a fixed item type *)

module type SItem = 
sig
   type item
   type t
   val empty : t
   val is_empty : t -> bool
   val length : t -> int
   val front : t -> item
   val back : t -> item
   val push_front : item -> t -> t
   val pop_front : t -> item * t
   val push_back : item -> t -> t
   val pop_back : t -> item * t
   val append : t -> t -> t
   val split_at : int -> t -> t * t
   val iter : (item -> unit) -> t -> unit
   val fold_left : ('a -> item -> 'a) -> 'a -> t -> 'a
   val fold_right : (item -> 'a -> 'a) -> t -> 'a -> 'a
   val to_list : t -> item list
end


(*---------------------------------------------------------------*)
(** Fixing the type of a polymorphic pure sequence *)

module SItemOfS (Item : Type.S) (Seq : S) 
   : SItem with type item = Item.t =
struct 
   type item = Item.t
   type t = item Seq.t
   include (Seq :
      sig 
      val empty : 'a Seq.t
      val is_empty : 'a Seq.t -> bool
      val length : 'a Seq.t -> int
      val front : 'a Seq.t -> 'a
      val back : 'a Seq.t -> 'a
      val push_front : 'a -> 'a Seq.t -> 'a Seq.t
      val pop_front : 'a Seq.t -> 'a * 'a Seq.t
      val push_back : 'a -> 'a Seq.t -> 'a Seq.t
      val pop_back : 'a Seq.t -> 'a * 'a Seq.t
      val append : 'a Seq.t -> 'a Seq.t -> 'a Seq.t
      val split_at : int -> 'a Seq.t -> 'a Seq.t * 'a Seq.t
      val iter : ('a -> unit) -> 'a Seq.t -> unit
      val fold_left : ('b -> 'a -> 'b) -> 'b -> 'a Seq.t -> 'b
      val fold_right : ('a -> 'b -> 'b) -> 'a Seq.t -> 'b -> 'b
      val to_list : 'a Seq.t -> 'a list
      end)
end
