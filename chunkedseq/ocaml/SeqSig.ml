

(*---------------------------------------------------------------*)
(** Signature of polymorphic ephemeral sequences *)

module type S = 
sig
   type 'a t 
   val create : 'a -> 'a t
   val is_empty : 'a t -> bool
   val get : 'a t -> int -> 'a
   val set : 'a t -> int -> 'a -> unit
   val length : 'a t -> int
   val back : 'a t -> 'a
   val front : 'a t -> 'a 
   val push_front :'a -> 'a t -> unit
   val pop_front : 'a t -> 'a
   val push_back : 'a -> 'a t -> unit
   val pop_back : 'a t -> 'a
   val transfer_to_back : 'a t -> 'a t -> unit
   val carve_back_at : int -> 'a t -> 'a t
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


(*---------------------------------------------------------------*)
(** Packaging of a pure sequence as an ephemeral sequence *)

module SeqOfPSeq (Seq : PSeqSig.S) : S = 
struct
   type 'a t = ('a Seq.t) ref
   let create d = 
      ref Seq.empty
   let is_empty s =
      Seq.is_empty !s
   let get s = assert false
      (*Seq.get !s*)
   let set s i v = assert false
      (*s := Seq.set s i v*)
   let length s = 
      Seq.length !s
   let front s =
      Seq.front !s
   let back s =
      Seq.back !s
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
   let transfer_to_back s1 s2 = 
      s2 := Seq.append !s1 !s2
   let carve_back_at i s = 
      let (r1,r2) = Seq.split_at i !s in
      s := r1;
      ref r2
   let iter f s =
      Seq.iter f !s
   let fold_left f i s =
      Seq.fold_left f i !s
   let fold_right f s i =
      Seq.fold_right f !s i
   let to_list s =
      Seq.to_list !s
end
