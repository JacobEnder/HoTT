Require Import Basics Types Pointed.
Require Import Cubical.DPath.
Require Import Algebra.AbGroups.
Require Import Truncations.
Require Import Homotopy.Suspension.
Require Import Homotopy.ClassifyingSpace.
Require Import Homotopy.HSpace.
Require Import Homotopy.HomotopyGroup.
Require Import TruncType.
Require Import WildCat.

(* Formalisation of Eilenberg-MacLane spaces *)

Local Open Scope pointed_scope.
Local Open Scope nat_scope.
Local Open Scope bg_scope.
Local Open Scope mc_mult_scope.


(** When X is 0-connected we see that Freudenthal doesn't let us characterise the loop space of a suspension. For this we need some extra assumptions about our space X.

Suppose X is a 0-connected, 1-truncated coherent H-space, then

  pTr 1 (loops (psusp X)) <~>* X

By coherent H-space we mean that left and right identity laws at the unit are the same.
*)

Section LicataFinsterLemma.

  Context `{Univalence} (X : pType)
    `{IsConnected 0 X} `{IsTrunc 1 X} `{IsHSpace X}
    {coh : left_identity mon_unit = right_identity mon_unit}.

  (** This encode-decode style proof is detailed in Eilenberg-MacLane Spaces in Homotopy Type Theory by Dan Licata and Eric Finster *)

  Local Definition P : Susp X -> Type
    := fun x => Tr 1 (North = x).

  Local Definition codes : Susp X -> 1 -Type.
  Proof.
    srapply Susp_rec.
    1: refine (Build_TruncType _ X).
    1: refine (Build_TruncType _ X).
    intro x.
    apply path_trunctype.
    apply (equiv_hspace_left_op x).
  Defined.

  Local Definition transport_codes_merid x y
    : transport codes (merid x) y = x * y.
  Proof.
    unfold codes.
    rewrite transport_idmap_ap.
    rewrite ap_compose.
    rewrite Susp_rec_beta_merid.
    rewrite ap_trunctype.
    by rewrite transport_path_universe_uncurried.
  Defined.

  Local Definition transport_codes_merid_V x
    : transport codes (merid mon_unit)^ x = x.
  Proof.
    unfold codes.
    rewrite transport_idmap_ap.
    rewrite ap_V.
    rewrite ap_compose.
    rewrite Susp_rec_beta_merid.
    rewrite ap_trunctype.
    rewrite transport_path_universe_V_uncurried.
    apply moveR_equiv_V.
    symmetry.
    cbn; apply left_identity.
  Defined.

  Local Definition encode : forall x, P x -> codes x.
  Proof.
    intro x.
    srapply Trunc_rec.
    intro p.
    exact (transport codes p mon_unit).
  Defined.

  Local Definition decode' : X -> Tr 1 (@North X = North).
  Proof.
    intro x.
    exact (tr (merid x @ (merid mon_unit)^)).
  Defined.

  Local Definition transport_decode' x y
    : transport P (merid x) (decode' y)
    = tr (merid y @ (merid mon_unit)^ @ merid x).
  Proof.
    unfold P.
    unfold decode'.
    rewrite transport_compose.
    generalize (merid x).
    generalize (merid y @ (merid mon_unit)^).
    intros p [].
    cbn; apply ap.
    symmetry.
    apply concat_p1.
  Defined.

  Local Definition encode_North_decode' x : encode North (decode' x) = x.
  Proof.
    cbn.
    rewrite transport_idmap_ap.
    rewrite ap_compose.
    rewrite ap_pp.
    rewrite ap_V.
    rewrite 2 Susp_rec_beta_merid.
    rewrite <- path_trunctype_V.
    rewrite <- path_trunctype_pp.
    rewrite ap_trunctype.
    rewrite transport_path_universe_uncurried.
    apply moveR_equiv_V; cbn.
    exact (right_identity _ @ (left_identity _)^).
  Defined.

  Local Definition merid_mu (x y : X)
    : tr (n:=1) (merid (x * y)) = tr (merid y @ (merid mon_unit)^ @ merid x).
  Proof.
    set (Q := fun a b : X => tr (n:=1) (merid (a * b))
      = tr (merid b @ (merid mon_unit)^ @ merid a)).
    srapply (@wedge_incl_elim_uncurried _ (-1) (-1) _
      mon_unit _ _ mon_unit _ Q _ _ x y);
    (* The try clause below is only needed for Coq <= 8.11 *)
    try (intros a b; cbn; unfold Q; apply istrunc_paths; exact _).
    unfold Q.
    srefine (_;_;_).
    { intro b.
      apply ap.
      symmetry.
      refine (concat_pp_p _ _ _ @ _).
      refine (ap _ (concat_Vp _) @ _).
      refine (concat_p1 _ @ _).
      apply ap.
      exact (left_identity b)^. }
    { intro a.
      apply ap.
      symmetry.
      refine (ap (fun x => concat x (merid a)) (concat_pV _) @ _).
      refine (concat_1p _ @ _).
      apply ap.
      exact (right_identity a)^. }
    simpl.
    apply ap, ap.
    rewrite <- coh.
    rewrite ? concat_p_pp.
    apply whiskerR.
    generalize (merid (mon_unit : X)).
    by intros [].
  Defined.

  Local Definition decode : forall x, codes x -> P x.
  Proof.
    srapply Susp_ind; cbn.
    1: apply decode'.
    { intro x.
      apply tr, merid, x. }
    intro x.
    srapply dp_path_transport^-1.
    apply dp_arrow.
    intro y.
    apply dp_path_transport.
    rewrite transport_codes_merid.
    rewrite transport_decode'.
    symmetry.
    apply merid_mu.
  Defined.

  Local Definition decode_encode : forall x (p : P x),
    decode x (encode x p) = p.
  Proof.
    intro x.
    srapply Trunc_ind.
    intro p.
    destruct p; cbv.
    apply ap, concat_pV.
  Defined.

  (* We could call this pequiv_ptr_loop_psusp but since we already used that for the Freudenthal case, it seems appropriate to name licata_finster for this one case *)
  Lemma licata_finster : pTr 1 (loops (psusp X)) <~>* X.
  Proof.
    srapply Build_pEquiv'.
    { srapply equiv_adjointify.
      1: exact (encode North).
      1: exact decode'.
      1: intro; apply encode_North_decode'.
      intro; apply decode_encode. }
    reflexivity.
  Defined.

End LicataFinsterLemma.


Section EilenbergMacLane.
  Context `{Univalence}.

  Fixpoint EilenbergMacLane (G : Group) (n : nat) : pType
    := match n with
        | 0    => Build_pType G _
        | 1    => pClassifyingSpace G
        | m.+1 => pTr m.+1 (psusp (EilenbergMacLane G m))
       end.

  Notation "'K(' G , n )" := (EilenbergMacLane G n).

  Global Instance istrunc_em {G : Group}  {n : nat} : IsTrunc n K(G, n).
  Proof.
    destruct n as [|[]]; exact _.
  Defined.

  Global Instance isconnected_em {G : Group} (n : nat)
    : IsConnected n K(G, n.+1).
  Proof.
    induction n; exact _.
  Defined.

  Local Open Scope trunc_scope.

  (* This is a variant of [pequiv_ptr_loop_psusp] from pSusp.v. All we are really using is that [n.+2 <= n +2+ n], but because of the use of [isconnmap_pred_add], the proof is a bit more specific to this case. *)
  Local Lemma pequiv_ptr_loop_psusp' (X : pType) (n : nat) `{IsConnected n.+1 X}
    : pTr n.+2 X <~>* pTr n.+2 (loops (psusp X)).
  Proof.
    snrapply Build_pEquiv.
    1: rapply (fmap (pTr _) (loop_susp_unit _)).
    nrapply O_inverts_conn_map.
    nrapply (isconnmap_pred_add n.-2).
    rewrite 2 trunc_index_add_succ.
    rapply conn_map_loop_susp_unit.
  Defined.

  Lemma pequiv_loops_em_em (G : AbGroup) (n : nat)
    : loops K(G, n.+1) <~>* K(G, n).
  Proof.
    destruct n.
    1: apply pequiv_loops_bg_g.
    change (loops (pTr n.+2 (psusp (K(G, n.+1)))) <~>* K(G, n.+1)).
    refine (_ o*E (ptr_loops _ _)^-1* ).
    destruct n.
    { srapply licata_finster.
      reflexivity. }
    refine ((pequiv_ptr (n:=n.+2))^-1* o*E _).
    symmetry; rapply pequiv_ptr_loop_psusp'.
  Defined.

  Definition pequiv_loops_em_g (G : AbGroup) (n : nat)
    : iterated_loops n K(G, n) <~>* G.
  Proof.
    induction n.
    - reflexivity.
    - refine (IHn o*E _ o*E unfold_iterated_loops' _ _).
      exact (emap (iterated_loops n) (pequiv_loops_em_em _ _)).
  Defined.

  (* For positive indices, we in fact get a group isomorphism. *)
  Definition equiv_g_pi_n_em (G : AbGroup) (n : nat)
    : GroupIsomorphism G (Pi n.+1 K(G, n.+1)).
  Proof.
    induction n.
    - apply grp_iso_g_pi1_bg.
    - snrapply (transitive_groupisomorphism _ _ _ IHn).
      symmetry.
      snrapply (transitive_groupisomorphism _ _ _ (groupiso_pi_loops _ _)).
      apply (groupiso_pi_functor _ (pequiv_loops_em_em _ _)).
  Defined.

End EilenbergMacLane.
