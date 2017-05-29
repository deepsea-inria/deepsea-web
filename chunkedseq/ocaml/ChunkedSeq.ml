
(*-----------------------------------------------------------------------------*)

module Make 
  (Capacity : CapacitySig.S) 
  (Chunk : SeqSig.S)  (* chunks of capacity Capacity.value *)
  (Middle : SeqSig.S) =
struct

(*-----------------------------------------------------------------------------*)

type 'a chunk = 'a Chunk.t

let capacity = Capacity.capacity

let is_full c = 
  Chunk.length c = capacity

(*-----------------------------------------------------------------------------*)

(** Representation *)

type 'a t = {
  mutable fo : 'a chunk;
  mutable fi : 'a chunk;
  mutable mid : ('a chunk) Middle.t;
  mutable bi : 'a chunk;
  mutable bo : 'a chunk; 
  default : 'a }

(** Creation *)

let create d = 
   let def = Chunk.create d in
   { fo = Chunk.create d;
     fi = Chunk.create d;
     mid = Middle.create def;
     bi = Chunk.create d;
     bo = Chunk.create d;
     default = d }

(** Emptiness test *)    
  
let is_empty s =
     Chunk.is_empty s.fo
  && Chunk.is_empty s.bo
  && Chunk.is_empty s.fi
  && Chunk.is_empty s.bi
  && Middle.is_empty s.mid

(** Push front *)

let push_front x s =
   let co = s.fo in
   if is_full co then begin
      let ci = s.fi in
      s.fi <- co;
      if Chunk.is_empty ci then begin
         s.fo <- ci;
      end else begin
         Middle.push_front ci s.mid;
         s.fo <- Chunk.create();
      end 
   end;
   Chunk.push_front x s.fo

(** Push back *)

let push_back x s =
   let co = s.bo in
   if is_full co then begin
      let ci = s.bi in
      s.bi <- co;
      if Chunk.is_empty ci then begin
         s.bo <- ci;
      end else begin
         Middle.push_back ci s.mid;
         s.bo <- Chunk.create();
      end 
   end;
   Chunk.push_back x s.bo

(** Pop front *)

let pop_front s =
   let co = s.fo in
   if not (Chunk.is_empty co) then begin
      Chunk.pop_front co
   end else begin
      let ci = s.fi in
      let m = s.mid in
      if not (Chunk.is_empty ci) then begin
         s.fo <- ci;
         s.fi <- co;
         Chunk.pop_front s.fo
      end else if not (Middle.is_empty m) then begin
         s.fo <- Middle.pop_front m;
         Chunk.pop_front s.fo
      end else if not (Chunk.is_empty s.bi) then begin
         s.fo <- s.bi;
         s.bi <- co;
         Chunk.pop_front s.fo
      end else begin
         Chunk.pop_front s.bo
      end
   end

(** Pop back *)

let pop_back s =
   let co = s.bo in
   if not (Chunk.is_empty co) then begin
      Chunk.pop_back co
   end else begin
      let ci = s.bi in
      let m = s.mid in
      if not (Chunk.is_empty ci) then begin
         s.bo <- ci;
         s.bi <- co;
         Chunk.pop_back s.bo
      end else if not (Middle.is_empty m) then begin
         s.bo <- Middle.pop_back m;
         Chunk.pop_back s.bo
      end else if not (Chunk.is_empty s.fi) then begin
         s.bo <- s.fi;
         s.fi <- co;
         Chunk.pop_back s.bo
      end else begin
         Chunk.pop_back s.fo
      end
   end
 
(** Push a buffer to the back of the mid sequence, 
    possibly merging it with the back chunk in the mid sequence *)
    (* TODO: optimize using a top_back operation *)

let mid_merge_back m c =
   let sc = Chunk.length c in
   if sc > 0 then begin
      if Middle.is_empty m then begin
         Middle.push_back c m
      end else begin
         let b = Middle.pop_back m in
         let sb = Chunk.length b in
         if sc + sb > capacity then begin
            Middle.push_back b m;
            Middle.push_back c m
         end else begin
            Chunk.transfer_to_back c b ;
            Middle.push_back b m;
         end
      end
   end

(** Symmetric to mid_merge_back *)
    (* TODO: optimize using a top_front operation *)

let mid_merge_front m c =
   let sc = Chunk.length c in
   if sc > 0 then begin
      if Middle.is_empty m then begin
         Middle.push_front c m
      end else begin
         let b = Middle.pop_front m in
         let sb = Chunk.length b in
         if sc + sb > capacity then begin
            Middle.push_front b m;
            Middle.push_front c m
         end else begin
            Chunk.transfer_to_back b c;
            Middle.push_front c m;
         end
      end
   end

(** Append to the back of s1 the items of s2; s2 becomes empty *)

let transfer_to_back s2 s1 =
   let m1 = s1.mid in
   let ci = s1.bi in
   let co = s1.bo in
   if Chunk.is_empty ci then begin
      mid_merge_back m1 co
   end else begin
      Middle.push_back ci m1;
      if not (Chunk.is_empty co)
         then Middle.push_back co m1;
   end;
   let m2 = s2.mid in
   let fi = s2.fi in
   let fo = s2.fo in
   if Chunk.is_empty fi then begin
      mid_merge_front m2 fo
   end else begin
      Middle.push_front fi m2;
      if not (Chunk.is_empty fo)
         then Middle.push_front fo m2;
   end;
   s1.bi <- s2.bi;
   s1.bo <- s2.bo;
   if   not (Middle.is_empty m1)
     && not (Middle.is_empty m2) then begin
      let c1 = Middle.pop_back m1 in
      let sc1 = Chunk.length c1 in
      let c2 = Middle.pop_front m2 in
      let sc2 = Chunk.length c2 in
      if sc1 + sc2 > capacity then begin
         Middle.push_back c1 m1;
         Middle.push_front c2 m2;
      end else begin
         Chunk.transfer_to_back c2 c1;
         Middle.push_back c1 m1;
      end
   end;
   Middle.transfer_to_back m2 m1;
   s2.fo <- Chunk.create s2.default;
   s2.fi <- Chunk.create s2.default;
   s2.bi <- Chunk.create s2.default;
   s2.bo <- Chunk.create s2.default

let split i s =
  assert false (* TODO: implement *)

end
