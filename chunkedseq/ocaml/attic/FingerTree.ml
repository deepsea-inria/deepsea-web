(** Implementation of FingerTrees --- translated and adpated 
    to OCaml from the Haskell version by Hinze and Paterson (2006).  *)
    

(*-----------------------------------------------------------------------------*)
(*-----------------------------------------------------------------------------*)

module type ReducerS =
  sig
    type item
    type meas
    val zero : meas
    val combine : meas -> meas -> meas
    val measure : item -> meas
  end


module type PureMeasuredSeqS = 
sig
   type item
   type meas
   type t
   val measure : t -> meas
   val empty : t
   val is_empty : t -> bool
   val front : t -> item 
   val back : t -> item
   val push_front : item -> t -> t
   val pop_front : t -> item * t
   val push_back : item -> t -> t
   val pop_back : t -> item * t
   val concat : t -> t -> t
   val split : (meas -> bool) -> t -> (t * item * t)
   val fold_left : ('a -> item -> 'a) -> 'a -> t -> 'a
   val fold_right : (item -> 'a -> 'a) -> t -> 'a -> 'a
   val to_list : t -> item list
end


(*-----------------------------------------------------------------------------*)
(*-----------------------------------------------------------------------------*)


module Make (R : ReducerS) : 
  (PureMeasuredSeqS with type item = R.item and type meas = R.meas) =
struct
   
(*-----------------------------------------------------------------------------*)

type item = R.item
type meas = R.meas

let combine2 m1 m2 =
  R.combine m1 m2

let combine3 m1 m2 m3 = 
  R.combine m1 (combine2 m2 m3)

let combine4 m1 m2 m3 m4 = 
  R.combine m1 (combine3 m2 m3 m4)

(* Note: the constructor "Tree_intro", "Digit_intro" and "Ftree_intro"
   are currently needed because of a limitation of my verification tool CFML. 
   This should have no incidence on peformance. *)

type tree = 
  | Tree_leaf of meas * item
  | Tree_node2 of meas * tree * tree 
  | Tree_node3 of meas * tree * tree * tree

(* Note: Digit0 is only used during transitions *)  

type digit = 
  | Digit0  
  | Digit1 of meas * tree
  | Digit2 of meas * tree * tree
  | Digit3 of meas * tree * tree * tree
  | Digit4 of meas * tree * tree * tree * tree

type ftree = 
  | Ftree_empty
  | Ftree_single of meas * tree
  | Ftree_deep of meas * digit * ftree * digit
  | Ftree_lazy of ftree Lazy.t

type t = ftree

(*---*)

let tree_cached = function
  | Tree_leaf (m,_) -> m
  | Tree_node2 (m,_,_) -> m
  | Tree_node3 (m,_,_,_) -> m

let digit_cached = function
  | Digit0 -> R.zero
  | Digit1 (m,_) -> m
  | Digit2 (m,_,_) -> m
  | Digit3 (m,_,_,_) -> m
  | Digit4 (m,_,_,_,_) -> m

let rec ftree_cached = function
  | Ftree_empty -> R.zero
  | Ftree_single (m,_) -> m
  | Ftree_deep (m,_,_,_) -> m
  | Ftree_lazy (lazy f) -> ftree_cached f

let measure =
   ftree_cached

(*---*)

let tree_leaf x =
  Tree_leaf (R.measure x, x)

let tree_node2 t1 t2 =
  let s = tree_cached in
  let m = combine2 (s t1) (s t2) in
  Tree_node2 (m, t1, t2)

let tree_node3 t1 t2 t3 =
  let s = tree_cached in
  let m = combine3 (s t1) (s t2) (s t3) in
  Tree_node3 (m, t1, t2, t3)

let digit0 = 
  Digit0

let digit1 t1 =
  let s = tree_cached in
  let m = s t1 in
  Digit1(m, t1)

let digit2 t1 t2 =
  let s = tree_cached in
  let m = combine2 (s t1) (s t2) in
  Digit2(m, t1, t2)

let digit3 t1 t2 t3 =
  let s = tree_cached in
  let m = combine3 (s t1) (s t2) (s t3) in
  Digit3(m, t1, t2, t3)

let digit4 t1 t2 t3 t4 =
  let s = tree_cached in
  let m = combine4 (s t1) (s t2) (s t3) (s t4) in
  Digit4(m, t1, t2, t3, t4)

let ftree_empty =
  Ftree_empty
 
let ftree_single t =
  let m = tree_cached t in
  Ftree_single(m, t)

let ftree_deep dl sub dr =
  let m = combine3 (digit_cached dl) (ftree_cached sub) (digit_cached dr) in
  Ftree_deep(m, dl, sub, dr)

(*---*)

let digit1_ m t1 = Digit1(m, t1)
let digit2_ m t1 t2 = Digit2(m, t1, t2)
let digit3_ m t1 t2 t3 = Digit3(m, t1, t2, t3)
let digit4_ m t1 t2 t3 t4 = Digit4(m, t1, t2, t3, t4)
let ftree_single_ m t = Ftree_single(m, t)
let ftree_deep_ m dl sub dr = Ftree_deep(m, dl, sub, dr)

(*---*)

let ftree_of_digit d =
  match d with
  | Digit0 -> ftree_empty
  | Digit1 (m, t1) -> ftree_single_ m t1
  | Digit2 (m, t1, t2) -> ftree_deep_ m (digit1 t1) ftree_empty (digit1 t2) 
  | Digit3 (m, t1, t2, t3) -> ftree_deep_ m (digit2 t1 t2) ftree_empty (digit1 t3) 
  | Digit4 (m, t1, t2, t3, t4) -> ftree_deep_ m (digit2 t1 t2) ftree_empty (digit2 t3 t4) 

let digit_of_tree t = 
  match t with
  | Tree_leaf (_, _) -> assert false
  | Tree_node2 (m, t1, t2) -> digit2_ m t1 t2 
  | Tree_node3 (m, t1, t2, t3) -> digit3_ m t1 t2 t3

(*---*)

let tree_item t =
   match t with
   | Tree_leaf (_, x) -> x
   | _ -> assert false

let digit_front d =
   match d with
   | Digit0 -> assert false
   | Digit1 (_, t1) -> tree_item t1
   | Digit2 (_, t1, t2) -> tree_item t1
   | Digit3 (_, t1, t2, t3) -> tree_item t1
   | Digit4 (_, t1, t2, t3, t4) -> tree_item t1

let rec front ff =
   match ff with
   | Ftree_empty -> assert false
   | Ftree_single (_, t) -> tree_item t
   | Ftree_deep (_, dl, fm, dr) -> digit_front dl
   | Ftree_lazy (lazy ff) -> front ff

let digit_back d =
   match d with
   | Digit0 -> assert false
   | Digit1 (_, t1) -> tree_item t1
   | Digit2 (_, t1, t2) -> tree_item t2
   | Digit3 (_, t1, t2, t3) -> tree_item t3
   | Digit4 (_, t1, t2, t3, t4) -> tree_item t4

let rec back ff =
   match ff with
   | Ftree_empty -> assert false
   | Ftree_single (_, t) -> tree_item t
   | Ftree_deep (_, dl, fm, dr) -> digit_back dr
   | Ftree_lazy (lazy ff) -> back ff

(*---*)

let digit_push_front t0 d = 
  match d with
  | Digit0 -> assert false
  | Digit1 (_, t1) -> digit2 t0 t1
  | Digit2 (_, t1, t2) -> digit3 t0 t1 t2
  | Digit3 (_, t1, t2, t3) -> digit4 t0 t1 t2 t3
  | Digit4 (_, _, _, _, _) -> assert false

let rec ftree_push_front t0 f =
 match f with
   | Ftree_empty -> 
       ftree_single t0
   | Ftree_single (_, t1) -> 
       ftree_deep (digit1 t0) ftree_empty (digit1 t1)
   | Ftree_deep (_, dl, fm, dr) ->
       begin match dl with
       | Digit4 (_, t1, t2, t3, t4) -> 
           let t = tree_node3 t2 t3 t4 in
           let fm2 = Ftree_lazy (lazy (ftree_push_front t fm)) in
           let dl2 = digit2 t0 t1 in
           ftree_deep dl2 fm2 dr
       | _ -> 
           let dl2 = digit_push_front t0 dl in
           ftree_deep dl2 fm dr
       end
  | Ftree_lazy (lazy f) -> 
       ftree_push_front t0 f

let push_front x f =
  ftree_push_front (tree_leaf x) f

(*---*)

let digit_pop_front d =
  match d with
  | Digit0 -> assert false
  | Digit1 (_, t1) -> (t1, digit0)
  | Digit2 (_, t1, t2) -> (t1, digit1 t2)
  | Digit3 (_, t1, t2, t3) -> (t1, digit2 t2 t3)
  | Digit4 (_, t1, t2, t3, t4) -> (t1, digit3 t2 t3 t4)

let rec ftree_pop_front f = 
  match f with
  | Ftree_empty -> 
      None
  | Ftree_single (_, t1) -> 
      Some (t1, ftree_empty)
  | Ftree_deep (_, dl, fm, dr) ->
      let (t1, dl2) = digit_pop_front dl in
      Some (t1, ftree_fix_front dl2 fm dr)
  | Ftree_lazy (lazy f) -> 
      ftree_pop_front f

and ftree_fix_front dl fm dr =
  match dl with
  | Digit0 ->
      begin match ftree_pop_front fm with
      | None -> 
          ftree_of_digit dr
      | Some (t2, fm2) -> 
          let dl2 = digit_of_tree t2 in
          ftree_deep dl2 fm2 dr
      end
  | _ -> ftree_deep dl fm dr

let pop_front ff =
  match ftree_pop_front ff with
  | None -> assert false
  | Some (t, ff2) -> 
     match t with
     | Tree_leaf (_, x) -> (x, ff2) 
     | _ -> assert false

(*---*)

let digit_push_back t0 d = 
  match d with
  | Digit0 -> assert false
  | Digit1 (_, t1) -> digit2 t1 t0
  | Digit2 (_, t1, t2) -> digit3 t1 t2 t0
  | Digit3 (_, t1, t2, t3) -> digit4 t1 t2 t3 t0
  | Digit4 (_, _, _, _, _) -> assert false

let rec ftree_push_back t0 f =
  match f with
  | Ftree_empty -> 
      ftree_single t0
  | Ftree_single (_, t1) -> 
      ftree_deep (digit1 t1) ftree_empty (digit1 t0)
  | Ftree_deep (_, dl, fm, dr) ->
      begin match dr with
      | Digit4 (_, t1, t2, t3, t4) -> 
          let t = tree_node3 t1 t2 t3 in
          let fm2 = Ftree_lazy (lazy (ftree_push_back t fm)) in
          let dr2 = digit2 t4 t0 in
          ftree_deep dl fm2 dr2
      | _ -> 
          let dr2 = digit_push_back t0 dr in
          ftree_deep dl fm dr2
      end
  | Ftree_lazy (lazy f) -> 
      ftree_push_back t0 f

let push_back x f =
  ftree_push_back (tree_leaf x) f

(*---*)

let digit_pop_back d =
  match d with
  | Digit0 -> assert false
  | Digit1 (_, t1) -> (t1, digit0)
  | Digit2 (_, t1, t2) -> (t2, digit1 t1)
  | Digit3 (_, t1, t2, t3) -> (t3, digit2 t1 t2)
  | Digit4 (_, t1, t2, t3, t4) -> (t4, digit3 t1 t2 t3)

let rec ftree_pop_back f = 
  match f with
  | Ftree_empty -> 
      None
  | Ftree_single (_, t1) -> 
      Some (t1, ftree_empty)
  | Ftree_deep (_, dl, fm, dr) ->
      let (t1, dr2) = digit_pop_back dr in
      Some (t1, ftree_fix_back dl fm dr2)
  | Ftree_lazy (lazy f) -> 
      ftree_pop_back f

and ftree_fix_back dl fm dr =
  match dr with
  | Digit0 ->
      begin match ftree_pop_back fm with
      | None -> 
          ftree_of_digit dl
      | Some (t2, fm2) -> 
          let dr2 = digit_of_tree t2 in
          ftree_deep dl fm2 dr2
      end
  | _ -> ftree_deep dl fm dr

let pop_back ff =
  match ftree_pop_back ff with
  | None -> assert false
  | Some (t, ff2) ->  
      match t with 
      | Tree_leaf (_, x) -> (x, ff2) 
      | _ -> assert false

(*---*)

let empty =
   ftree_empty

(*---*)

let is_empty ff =
   match ff with
   | Ftree_empty -> true
   | _ -> false

(*---*)

let digit_split p i d : digit * tree * digit = 
  match d with
  | Digit0 -> assert false
  | Digit1 (_, t1) -> 
      (digit0, t1, digit0)
  | Digit2 (_, t1, t2) ->
      let i1 = combine2 i (tree_cached t1) in
      if p i1 then (digit0, t1, digit1 t2) else 
         (digit1 t1, t2, digit0)
  | Digit3 (_, t1, t2, t3) ->
      let i1 = combine2 i (tree_cached t1) in
      if p i1 then (digit0, t1, digit2 t2 t3) else
         let i11 = combine2 i1 (tree_cached t2) in
         if p i11 then (digit1 t1, t2, digit1 t3) else
            (digit2 t1 t2, t3, digit0)
  | Digit4 (_, t1, t2, t3, t4) ->
       let i1 = combine2 i (tree_cached t1) in
       if p i1 then (digit0, t1, digit3 t2 t3 t4) else 
         let i11 = combine2 i1 (tree_cached t2) in
         if p i11 then (digit1 t1, t2, digit2 t3 t4) else
            let i111 = combine2 i11 (tree_cached t3) in
            if p i111 then (digit2 t1 t2, t3, digit1 t4) else 
               (digit3 t1 t2 t3, t4, digit0)

let rec ftree_split p i f : ftree * tree * ftree =
  match f with
  | Ftree_empty -> 
      assert false
  | Ftree_single (_, t) ->
      (ftree_empty, t, ftree_empty)
  | Ftree_deep (_, dl, fm, dr) ->
      let vdl = combine2 i (digit_cached dl) in
      if p vdl then
         let (dll, dlm, dlr) = digit_split p i dl in
         (ftree_of_digit dll, dlm, ftree_fix_front dlr fm dr)
      else
         let vfm = combine2 vdl (ftree_cached fm) in
         if p vfm then
           let (fml, fmm, fmr) = ftree_split p vdl fm in
           let fmmd = digit_of_tree fmm in
           let i2 = (combine2 vdl (ftree_cached fml)) in
           let (fmml, fmmm, fmmr) = digit_split p i2 fmmd in
           (ftree_fix_back dl fml fmml, fmmm, ftree_fix_front fmmr fmr dr)
         else
           let (drl, drm, drr) = digit_split p vfm dr in
           (ftree_fix_back dl fm drl, drm, ftree_of_digit drr)
  | Ftree_lazy (lazy f) -> 
      ftree_split p i f

let split p ff : ftree * R.item * ftree =   
  let (ftl, t, ftr) = ftree_split p R.zero ff in
  match t with
  | Tree_leaf (_, x) -> (ftl, x, ftr)
  | _ -> assert false

(*---*)

let merge_digit_list d acc : tree list =
  match d with
  | Digit0 -> acc
  | Digit1 (_, t1) -> t1::acc
  | Digit2 (_, t1, t2) -> t1::t2::acc
  | Digit3 (_, t1, t2, t3) -> t1::t2::t3::acc
  | Digit4 (_, t1, t2, t3, t4) -> t1::t2::t3::t4::acc

let digit_from_tree_list ts : digit =
  match ts with
  | [] -> assert false
  | t1::[] -> digit1 t1
  | t1::t2::[] -> digit2 t1 t2
  | t1::t2::t3::[] -> digit3 t1 t2 t3
  | t1::t2::t3::t4::[] -> digit4 t1 t2 t3 t4
  | _ -> assert false

let ftree_digit_push_front d f = 
  let ts = merge_digit_list d [] in
  List.fold_right (fun t f' -> ftree_push_front t f') ts f

let ftree_digit_push_back d f =
  let ts = merge_digit_list d [] in
  List.fold_left (fun f' t -> ftree_push_back t f') f ts

let merge_digits d1 d2 d3 : digit =
  let rec aux = function
    | [] | _::[] -> assert false
    | t1::t2::[] -> [tree_node2 t1 t2]
    | t1::t2::t3::[] -> [tree_node3 t1 t2 t3]
    | t1::t2::t3::t4::[] -> [tree_node2 t1 t2; tree_node2 t3 t4]
    | t1::t2::t3::ts -> (tree_node3 t1 t2 t3)::(aux ts)
    in
  let m = merge_digit_list in
  let ts = m d1 (m d2 (m d3 [])) in
  digit_from_tree_list (aux ts)
  
let rec merge_with_digit fl d fr : ftree = 
  match fl, fr with
  | Ftree_empty, _ -> 
      ftree_digit_push_front d fr
  | _, Ftree_empty -> 
      ftree_digit_push_back d fl
  | Ftree_single (_, t), _ -> 
      ftree_push_front t (ftree_digit_push_front d fr)
  | _, Ftree_single (_, t) -> 
      ftree_push_back t (ftree_digit_push_back d fl)
  | Ftree_deep (_, dll, flm, dlr), Ftree_deep (_, drl, frm, drr) ->
      let d = merge_digits dlr d drl in
      let fm = Ftree_lazy (lazy (merge_with_digit flm d frm)) in
      ftree_deep dll fm drr
  | Ftree_lazy (lazy fl), _ -> 
      merge_with_digit fl d fr
  | _, Ftree_lazy (lazy fr) -> 
      merge_with_digit fl d fr

let concat ffl ffr =
  merge_with_digit ffl digit0 ffr

(*-----------------------------------------------------------------------------*)

let rec tree_fold_left g i t =
   let s = tree_fold_left g in
   match t with
    | Tree_leaf (_, x) -> g i x
    | Tree_node2 (_, t1, t2) -> s (s i t1) t2
    | Tree_node3 (_, t1, t2, t3) -> s (s (s i t1) t2) t3

let rec tree_fold_right g t i =
   let s = tree_fold_right g in
   match t with
    | Tree_leaf (_, x) -> g x i
    | Tree_node2 (_, t1, t2) -> s t1 (s t2 i)
    | Tree_node3 (_, t1, t2, t3) -> s t1 (s t2 (s t3 i))

let digit_fold_left g i d =
   let s = tree_fold_left g in
   match d with
    | Digit0 -> i
    | Digit1 (_, t1) -> s i t1
    | Digit2 (_, t1, t2) -> s (s i t1) t2
    | Digit3 (_, t1, t2, t3) -> s (s (s i t1) t2) t3
    | Digit4 (_, t1, t2, t3, t4) -> s (s (s (s i t1) t2) t3) t4

let digit_fold_right g d i =
   let s = tree_fold_right g in
   match d with
    | Digit0 -> i
    | Digit1 (_, t1) -> s t1 i
    | Digit2 (_, t1, t2) -> s t1 (s t2 i)  
    | Digit3 (_, t1, t2, t3) -> s t1 (s t2 (s t3 i))
    | Digit4 (_, t1, t2, t3, t4) -> s t1 (s t2 (s t3 (s t4 i)))

let rec fold_left g i f =
   match f with
  | Ftree_empty -> 
      i
  | Ftree_single (_, t1) -> 
      tree_fold_left g i t1
  | Ftree_deep (_, dl, fm, dr) ->
      let i1 = digit_fold_left g i dl in
      let i2 = fold_left g i1 fm in
      let i3 = digit_fold_left g i2 dr in
      i3
  | Ftree_lazy (lazy f) -> 
      fold_left g i f

let rec fold_right g f i =
   match f with
  | Ftree_empty -> 
      i
  | Ftree_single (_, t1) -> 
      tree_fold_right g t1 i
  | Ftree_deep (_, dl, fm, dr) ->
      digit_fold_right g dl (fold_right g fm (digit_fold_right g dr i))
  | Ftree_lazy (lazy f) -> 
      fold_right g f i
 
(*-----------------------------------------------------------------------------*)

let of_list f =
   List.fold_right (fun x acc -> push_front x acc) f ftree_empty

let to_list f =
   fold_right (fun x acc -> x::acc) f []

end


(*-----------------------------------------------------------------------------*)
(*-----------------------------------------------------------------------------*)

(** Specialization to sequences *)

module Make (Item : TypeSig.S)
  : (PSeq.S with type item = Item.t) = 
struct

   include FingerTree.Make(struct
         type item = Item.t
         type meas = int
         let zero = 0
         let combine = (+)
         let measure x = 1
      end
      )

   let length = measure

   let split_at i f =
      let (f1,v,f2) = split (fun k -> k >= i) f in
      (f1, push_front v f2)

end
 

