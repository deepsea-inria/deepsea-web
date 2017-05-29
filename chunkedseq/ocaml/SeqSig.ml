

(*---------------------------------------------------------------*)
(** Signature of polymorphic ephemeral sequences *)

module type S = 
sig
   type 'a t 
   val create : unit -> 'a t
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
   (* 
   val iter : ('a -> unit) -> 'a t -> unit
   val fold_left : ('b -> 'a -> 'b) -> 'b -> 'a t -> 'b
   val fold_right : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b
   *)
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


(*---------------------------------------------------------------*)
(** Signature of ephemeral sequences, for a fixed type of items *)

module type SItem = 
sig
   type item
   type t
   val create : unit -> t
   val length : t -> int
   val push_front :  item -> t -> unit
   val pop_front : t -> item
   val push_back : item -> t -> unit
   val pop_back : t -> item
   val append : t -> t -> t
   val carve_back_at : int -> t -> t * t
   (*
   val iter : (item -> unit) -> t -> unit
   val fold_left : ('a -> item -> 'a) -> 'a -> t -> 'a
   val fold_right : (item -> 'a -> 'a) -> t -> 'a -> 'a
   *)
   val to_list : t -> item list 
end


(*---------------------------------------------------------------*)
(** Packaging of a pure sequence as an ephemeral sequence, 
    for a fixed type of items *)

module SeqOfPSeq (Seq : PSeqSig.SItem) : (SItem with type item = Seq.item) = 
struct
   type item = Seq.item
   type t = Seq.t ref
   let create () = 
      ref Seq.empty
   let length s = 
      Seq.length !s
   let push_front x s = 
      s := Seq.push_front x !s
   let pop_front s = 
      let (x,r2) = Seq.pop_front !s in
      s := r2;
      x
   let push_back x s = 
      s := Seq.push_back x !s
   let pop_back s = 
      let (x,r2) = Seq.pop_back !s in
      s := r2;
      x
   let append s1 s2 = 
      ref (Seq.append !s1 !s2)
   let carve_back_at i s = 
      let (r1,r2) = Seq.split_at i !s in
      (ref r1, ref r2)
   let to_list s =
      Seq.to_list !s
end
