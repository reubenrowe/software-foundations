(** * IndProp: Inductively Defined Propositions *)

Set Warnings "-notation-overridden,-parsing,-deprecated-hint-without-locality".
From LF Require Export Logic.
From Coq Require Import Lia.

(* ################################################################# *)
(** * Inductively Defined Propositions *)

(** In the [Logic] chapter, we looked at several ways of writing
    propositions, including conjunction, disjunction, and existential
    quantification.  In this chapter, we bring yet another new tool
    into the mix: _inductively defined propositions_.

    _Note_: For the sake of simplicity, most of this chapter uses an
    inductive definition of "evenness" as a running example.  This is
    arguably a bit confusing, since we already have a perfectly good
    way of defining evenness as a proposition ("[n] is even if it is
    equal to the result of doubling some number").  Rest assured that
    we will see many more compelling examples of inductively defined
    propositions toward the end of this chapter and in future
    chapters. *)

(** We've already seen two ways of stating a proposition that a number
    [n] is even: We can say

      (1) [even n = true], or

      (2) [exists k, n = double k].

    A third possibility that we'll explore here is to say that [n] is
    even if we can _establish_ its evenness from the following rules:

       - Rule [ev_0]: The number [0] is even.
       - Rule [ev_SS]: If [n] is even, then [S (S n)] is even. *)

(** To illustrate how this new definition of evenness works,
    let's imagine using it to show that [4] is even. By rule [ev_SS],
    it suffices to show that [2] is even. This, in turn, is again
    guaranteed by rule [ev_SS], as long as we can show that [0] is
    even. But this last fact follows directly from the [ev_0] rule. *)

(** We will see many definitions like this one during the rest
    of the course.  For purposes of informal discussions, it is
    helpful to have a lightweight notation that makes them easy to
    read and write.  _Inference rules_ are one such notation.  (We'll
    use [ev] for the name of this property, since [even] is already
    used.)

                              ------------             (ev_0)
                                 ev 0

                                 ev n
                            ----------------          (ev_SS)
                             ev (S (S n))
*)

(** Each of the textual rules that we started with is
    reformatted here as an inference rule; the intended reading is
    that, if the _premises_ above the line all hold, then the
    _conclusion_ below the line follows.  For example, the rule
    [ev_SS] says that, if [n] satisfies [ev], then [S (S n)] also
    does.  If a rule has no premises above the line, then its
    conclusion holds unconditionally.

    We can represent a proof using these rules by combining rule
    applications into a _proof tree_. Here's how we might transcribe
    the above proof that [4] is even:

                             --------  (ev_0)
                              ev 0
                             -------- (ev_SS)
                              ev 2
                             -------- (ev_SS)
                              ev 4
*)

(** (Why call this a "tree", rather than a "stack", for example?
    Because, in general, inference rules can have multiple premises.
    We will see examples of this shortly.) *)

(* ================================================================= *)
(** ** Inductive Definition of Evenness *)

(** Putting all of this together, we can translate the definition of
    evenness into a formal Coq definition using an [Inductive]
    declaration, where each constructor corresponds to an inference
    rule: *)

Inductive ev : nat -> Prop :=
  | ev_0 : ev 0
  | ev_SS (n : nat) (H : ev n) : ev (S (S n)).

(** This definition is interestingly different from previous uses of
    [Inductive].  For one thing, we are defining not a [Type] (like
    [nat]) or a function yielding a [Type] (like [list]), but rather a
    function from [nat] to [Prop] -- that is, a property of numbers.
    But what is really new is that, because the [nat] argument of
    [ev] appears to the _right_ of the colon on the first line, it
    is allowed to take different values in the types of different
    constructors: [0] in the type of [ev_0] and [S (S n)] in the type
    of [ev_SS].  Accordingly, the type of each constructor must be
    specified explicitly (after a colon), and each constructor's type
    must have the form [ev n] for some natural number [n].

    In contrast, recall the definition of [list]:

    Inductive list (X:Type) : Type :=
      | nil
      | cons (x : X) (l : list X).

   This definition introduces the [X] parameter _globally_, to the
   _left_ of the colon, forcing the result of [nil] and [cons] to be
   the same (i.e., [list X]).  Had we tried to bring [nat] to the left
   of the colon in defining [ev], we would have seen an error: *)

Fail Inductive wrong_ev (n : nat) : Prop :=
  | wrong_ev_0 : wrong_ev 0
  | wrong_ev_SS (H: wrong_ev n) : wrong_ev (S (S n)).
(* ===> Error: Last occurrence of "[wrong_ev]" must have "[n]"
        as 1st argument in "[wrong_ev 0]". *)

(** In an [Inductive] definition, an argument to the type constructor
    on the left of the colon is called a "parameter", whereas an
    argument on the right is called an "index" or "annotation."

    For example, in [Inductive list (X : Type) := ...], the [X] is a
    parameter; in [Inductive ev : nat -> Prop := ...], the unnamed
    [nat] argument is an index. *)

(** We can think of this as defining a Coq property [ev : nat ->
    Prop], together with "evidence constructors" [ev_0 : ev 0]
    and [ev_SS : forall n, ev n -> ev (S (S n))]. *)

(** These evidence constructors can be thought of as "primitive
    evidence of evenness", and they can be used just like proven
    theorems.  In particular, we can use Coq's [apply] tactic with the
    constructor names to obtain evidence for [ev] of particular
    numbers... *)

Theorem ev_4 : ev 4.
Proof. apply ev_SS. apply ev_SS. apply ev_0. Qed.

(** ... or we can use function application syntax to combine several
    constructors: *)

Theorem ev_4' : ev 4.
Proof. apply (ev_SS 2 (ev_SS 0 ev_0)). Qed.

(** In this way, we can also prove theorems that have hypotheses
    involving [ev]. *)

Theorem ev_plus4 : forall n, ev n -> ev (4 + n).
Proof.
  intros n. simpl. intros Hn.
  apply ev_SS. apply ev_SS. apply Hn.
Qed.

(** **** Exercise: 1 star, standard (ev_double) *)
Theorem ev_double : forall n,
  ev (double n).
Proof.
  intros.
  induction n as [| n' IH ].
  - simpl. apply ev_0.
  - simpl. apply ev_SS. apply IH.  
Qed.
(** [] *)

(* ################################################################# *)
(** * Using Evidence in Proofs *)

(** Besides _constructing_ evidence that numbers are even, we can also
    _destruct_ such evidence, which amounts to reasoning about how it
    could have been built.

    Introducing [ev] with an [Inductive] declaration tells Coq not
    only that the constructors [ev_0] and [ev_SS] are valid ways to
    build evidence that some number is [ev], but also that these two
    constructors are the _only_ ways to build evidence that numbers
    are [ev]. *)

(** In other words, if someone gives us evidence [E] for the assertion
    [ev n], then we know that [E] must be one of two things:

      - [E] is [ev_0] (and [n] is [O]), or
      - [E] is [ev_SS n' E'] (and [n] is [S (S n')], where [E'] is
        evidence for [ev n']). *)

(** This suggests that it should be possible to analyze a
    hypothesis of the form [ev n] much as we do inductively defined
    data structures; in particular, it should be possible to argue by
    _induction_ and _case analysis_ on such evidence.  Let's look at a
    few examples to see what this means in practice. *)

(* ================================================================= *)
(** ** Inversion on Evidence *)

(** Suppose we are proving some fact involving a number [n], and
    we are given [ev n] as a hypothesis.  We already know how to
    perform case analysis on [n] using [destruct] or [induction],
    generating separate subgoals for the case where [n = O] and the
    case where [n = S n'] for some [n'].  But for some proofs we may
    instead want to analyze the evidence for [ev n] _directly_. As
    a tool, we can prove our characterization of evidence for
    [ev n], using [destruct]. *)

Theorem ev_inversion :
  forall (n : nat), ev n ->
    (n = 0) \/ (exists n', n = S (S n') /\ ev n').
Proof.
  intros n E.
  destruct E as [ | n' E'] eqn:EE.
  - (* E = ev_0 : ev 0 *)
    left. reflexivity.
  - (* E = ev_SS n' E' : ev (S (S n')) *)
    right. exists n'. split. reflexivity. apply E'.
Qed.

(** Facts like this are often called "inversion lemmas" because they
    allow us to "invert" some given information to reason about all
    the different ways it could have been derived.

    Here, there are two ways to prove that a number is [ev], and
    the inversion lemma makes this explicit. *)

(** The following theorem can easily be proved using [destruct] on
    evidence. *)

Theorem ev_minus2 : forall n,
  ev n -> ev (pred (pred n)).
Proof.
  intros n E.
  destruct E as [| n' E'] eqn:EE.
  - (* E = ev_0 *) simpl. apply ev_0.
  - (* E = ev_SS n' E' *) simpl. apply E'.
Qed.

(** However, this variation cannot easily be handled with just
    [destruct]. *)

Theorem evSS_ev : forall n,
  ev (S (S n)) -> ev n.
(** Intuitively, we know that evidence for the hypothesis cannot
    consist just of the [ev_0] constructor, since [O] and [S] are
    different constructors of the type [nat]; hence, [ev_SS] is the
    only case that applies.  Unfortunately, [destruct] is not smart
    enough to realize this, and it still generates two subgoals.  Even
    worse, in doing so, it keeps the final goal unchanged, failing to
    provide any useful information for completing the proof.  *)
Proof.
  intros n E.
  destruct E as [| n' E'] eqn:EE.
  - (* E = ev_0. *)
    (* We must prove that [n] is even from no assumptions! *)
Abort.

(** What happened, exactly?  Calling [destruct] has the effect of
    replacing all occurrences of the property argument by the values
    that correspond to each constructor.  This is enough in the case
    of [ev_minus2] because that argument [n] is mentioned directly
    in the final goal. However, it doesn't help in the case of
    [evSS_ev] since the term that gets replaced ([S (S n)]) is not
    mentioned anywhere. *)

(** If we [remember] that term [S (S n)], the proof goes
    through.  (We'll discuss [remember] in more detail below.) *)

Theorem evSS_ev_remember : forall n,
  ev (S (S n)) -> ev n.
Proof.
  intros n E. remember (S (S n)) as k eqn:Hk.
  destruct E as [|n' E'] eqn:EE.
  - (* E = ev_0 *)
    (* Now we do have an assumption, in which [k = S (S n)] has been
       rewritten as [0 = S (S n)] by [destruct]. That assumption
       gives us a contradiction. *)
    discriminate Hk.
  - (* E = ev_S n' E' *)
    (* This time [k = S (S n)] has been rewritten as [S (S n') = S (S n)]. *)
    injection Hk as Heq. rewrite <- Heq. apply E'.
Qed.

(** Alternatively, the proof is straightforward using the inversion
    lemma that we proved above. *)

Theorem evSS_ev : forall n, ev (S (S n)) -> ev n.
Proof.
  intros n H. apply ev_inversion in H.
  destruct H as [H0|H1].
  - discriminate H0.
  - destruct H1 as [n' [Hnm Hev]]. injection Hnm as Heq.
    rewrite Heq. apply Hev.
Qed.

(** Note how both proofs produce two subgoals, which correspond
    to the two ways of proving [ev].  The first subgoal is a
    contradiction that is discharged with [discriminate].  The second
    subgoal makes use of [injection] and [rewrite].  Coq provides a
    handy tactic called [inversion] that factors out that common
    pattern.

    The [inversion] tactic can detect (1) that the first case ([n =
    0]) does not apply and (2) that the [n'] that appears in the
    [ev_SS] case must be the same as [n].  It has an "[as]" variant
    similar to [destruct], allowing us to assign names rather than
    have Coq choose them. *)

Theorem evSS_ev' : forall n,
  ev (S (S n)) -> ev n.
Proof.
  intros n E.
  inversion E as [| n' E' Heq].
  (* We are in the [E = ev_SS n' E'] case now. *)
  apply E'.
Qed.

(** The [inversion] tactic can apply the principle of explosion to
    "obviously contradictory" hypotheses involving inductively defined
    properties, something that takes a bit more work using our
    inversion lemma. For example: *)

Theorem one_not_even : ~ ev 1.
Proof.
  intros H. apply ev_inversion in H.
  destruct H as [ | [m [Hm _]]].
    - discriminate H.
  - discriminate Hm.
Qed.

Theorem one_not_even' : ~ ev 1.
Proof.
  intros H. inversion H. Qed.

(** **** Exercise: 1 star, standard (inversion_practice)

    Prove the following result using [inversion].  (For extra practice,
    you can also prove it using the inversion lemma.) *)

Theorem SSSSev__even : forall n,
  ev (S (S (S (S n)))) -> ev n.
Proof.
  intros n E.
  inversion E as [| n' E' H ].
  inversion E' as [| n'' E'' H' ].
  apply E''.
Qed.

Theorem SSSSev__even' : forall n,
  ev (S (S (S (S n)))) -> ev n.
Proof.
  intros n H.
  apply ev_inversion in H.
  destruct H as [| [ n' [ E H' ] ] ].
  - discriminate.
  - injection E as E'.
    rewrite <- E' in H'. apply ev_inversion in H'.
    destruct H' as [| [ n'' [ E2 H'' ] ]].
    + discriminate.
    + injection E2 as E2'. rewrite E2'. apply H''.  
Qed.
(** [] *)

(** **** Exercise: 1 star, standard (ev5_nonsense)

    Prove the following result using [inversion]. *)

Theorem ev5_nonsense :
  ev 5 -> 2 + 2 = 9.
Proof.
  intros H.
  inversion H as [| n H' E ].
  inversion H' as [| n' H'' E' ].
  inversion H''. 
Qed.
(** [] *)

(** The [inversion] tactic does quite a bit of work. For
    example, when applied to an equality assumption, it does the work
    of both [discriminate] and [injection]. In addition, it carries
    out the [intros] and [rewrite]s that are typically necessary in
    the case of [injection]. It can also be applied, more generally,
    to analyze evidence for inductively defined propositions.  As
    examples, we'll use it to re-prove some theorems from chapter
    [Tactics].  (Here we are being a bit lazy by omitting the [as]
    clause from [inversion], thereby asking Coq to choose names for
    the variables and hypotheses that it introduces.) *)

Theorem inversion_ex1 : forall (n m o : nat),
  [n; m] = [o; o] ->
  [n] = [m].
Proof.
  intros n m o H. inversion H. reflexivity. Qed.

Theorem inversion_ex2 : forall (n : nat),
  S n = O ->
  2 + 2 = 5.
Proof.
  intros n contra. inversion contra. Qed.

(** Here's how [inversion] works in general.  Suppose the name
    [H] refers to an assumption [P] in the current context, where [P]
    has been defined by an [Inductive] declaration.  Then, for each of
    the constructors of [P], [inversion H] generates a subgoal in which
    [H] has been replaced by the exact, specific conditions under
    which this constructor could have been used to prove [P].  Some of
    these subgoals will be self-contradictory; [inversion] throws
    these away.  The ones that are left represent the cases that must
    be proved to establish the original goal.  For those, [inversion]
    adds all equations into the proof context that must hold of the
    arguments given to [P] (e.g., [S (S n') = n] in the proof of
    [evSS_ev]). *)

(** The [ev_double] exercise above shows that our new notion of
    evenness is implied by the two earlier ones (since, by
    [even_bool_prop] in chapter [Logic], we already know that
    those are equivalent to each other). To show that all three
    coincide, we just need the following lemma. *)

Lemma ev_Even_firsttry : forall n,
  ev n -> Even n.
Proof.
  (* WORKED IN CLASS *)
  unfold Even.

(** We could try to proceed by case analysis or induction on [n].  But
    since [ev] is mentioned in a premise, this strategy would
    probably lead to a dead end, because (as we've noted before) the
    induction hypothesis will talk about n-1 (which is _not_ even!).
    Thus, it seems better to first try [inversion] on the evidence for
    [ev].  Indeed, the first case can be solved trivially. And we can
    seemingly make progress on the second case with a helper lemma. *)

  intros n E. inversion E as [EQ' | n' E' EQ'].
  - (* E = ev_0 *)
    exists 0. reflexivity.
  - (* E = ev_SS n' E' *)

(** Unfortunately, the second case is harder.  We need to show [exists
    n0, S (S n') = double n0], but the only available assumption is
    [E'], which states that [ev n'] holds.  Since this isn't
    directly useful, it seems that we are stuck and that performing
    case analysis on [E] was a waste of time.

    If we look more closely at our second goal, however, we can see
    that something interesting happened: By performing case analysis
    on [E], we were able to reduce the original result to a similar
    one that involves a _different_ piece of evidence for [ev]:
    namely [E'].  More formally, we can finish our proof by showing
    that

        exists k', n' = double k',

    which is the same as the original statement, but with [n'] instead
    of [n].  Indeed, it is not difficult to convince Coq that this
    intermediate result suffices. *)

    assert (H: (exists k', n' = double k') -> (exists n0, S (S n') = double n0)).
    { intros [k' EQ'']. exists (S k'). simpl. rewrite <- EQ''. reflexivity. }
    apply H.

    (** Unforunately, now we are stuck. To make that apparent, let's move
        [E'] back into the goal from the hypotheses. *)

    generalize dependent E'.

    (** Now it is clear we are trying to prove another instance of the
        same theorem we set out to prove.  This instance is with [n'],
        instead of [n], where [n'] is a smaller natural number than [n]. *)
Abort.

(* ================================================================= *)
(** ** Induction on Evidence *)

(** If this looks familiar, it is no coincidence: We've encountered
    similar problems in the [Induction] chapter, when trying to
    use case analysis to prove results that required induction.  And
    once again the solution is... induction! *)

(** The behavior of [induction] on evidence is the same as its
    behavior on data: It causes Coq to generate one subgoal for each
    constructor that could have used to build that evidence, while
    providing an induction hypothesis for each recursive occurrence of
    the property in question.

    To prove a property of [n] holds for all numbers for which [ev
    n] holds, we can use induction on [ev n]. This requires us to
    prove two things, corresponding to the two ways in which [ev n]
    could have been constructed. If it was constructed by [ev_0], then
    [n=0], and the property must hold of [0]. If it was constructed by
    [ev_SS], then the evidence of [ev n] is of the form [ev_SS n'
    E'], where [n = S (S n')] and [E'] is evidence for [ev n']. In
    this case, the inductive hypothesis says that the property we are
    trying to prove holds for [n']. *)

(** Let's try our current lemma again: *)

Lemma ev_Even : forall n,
  ev n -> Even n.
Proof.
  intros n E.
  induction E as [|n' E' IH].
  - (* E = ev_0 *)
    unfold Even. exists 0. reflexivity.
  - (* E = ev_SS n' E'
       with IH : Even E' *)
    unfold Even in IH.
    destruct IH as [k Hk].
    rewrite Hk.
    unfold Even. exists (S k). simpl. reflexivity.
Qed.

(** Here, we can see that Coq produced an [IH] that corresponds
    to [E'], the single recursive occurrence of [ev] in its own
    definition.  Since [E'] mentions [n'], the induction hypothesis
    talks about [n'], as opposed to [n] or some other number. *)

(** The equivalence between the second and third definitions of
    evenness now follows. *)

Theorem ev_Even_iff : forall n,
  ev n <-> Even n.
Proof.
  intros n. split.
  - (* -> *) apply ev_Even.
  - (* <- *) unfold Even. intros [k Hk]. rewrite Hk. apply ev_double.
Qed.

(** As we will see in later chapters, induction on evidence is a
    recurring technique across many areas, and in particular when
    formalizing the semantics of programming languages, where many
    properties of interest are defined inductively. *)

(** The following exercises provide simple examples of this
    technique, to help you familiarize yourself with it. *)

(** **** Exercise: 2 stars, standard (ev_sum) *)
Theorem ev_sum : forall n m, ev n -> ev m -> ev (n + m).
Proof.
  intros n m Hn Hm.
  induction Hn as [| n' Hn' IH ].
  - simpl. apply Hm.
  - rewrite add_comm.
    rewrite <- plus_n_Sm. rewrite <- plus_n_Sm.
    rewrite add_comm.
    apply ev_SS.
    apply IH.
Qed.
(** [] *)

(** **** Exercise: 4 stars, advanced, optional (ev'_ev)

    In general, there may be multiple ways of defining a
    property inductively.  For example, here's a (slightly contrived)
    alternative definition for [ev]: *)

Inductive ev' : nat -> Prop :=
  | ev'_0 : ev' 0
  | ev'_2 : ev' 2
  | ev'_sum n m (Hn : ev' n) (Hm : ev' m) : ev' (n + m).

(** Prove that this definition is logically equivalent to the old one.
    To streamline the proof, use the technique (from [Logic]) of
    applying theorems to arguments, and note that the same technique
    works with constructors of inductively defined propositions. *)

Theorem ev'_ev : forall n, ev' n <-> ev n.
Proof.
  intros. split.
  - intros ev'H.
    induction ev'H as [ | | n1 n2 Hn1 IHn1 Hn2 IHn2 ].
    * apply ev_0.
    * apply ev_SS. apply ev_0.
    * apply ev_sum. apply IHn1. apply IHn2.
  - intros evH.
    induction evH as [| n' Hn' IH ].
    * apply ev'_0.
    * apply (ev'_sum 2). apply ev'_2. apply IH.
Qed.
(** [] *)

(** **** Exercise: 3 stars, advanced, especially useful (ev_ev__ev)

    There are two pieces of evidence you could attempt to induct upon
    here. If one doesn't work, try the other. *)

Theorem ev_ev__ev : forall n m,
  ev (n+m) -> ev n -> ev m.
Proof.
  intros n m Hnm Hn.
  induction Hn as [| n' Hn' IH ].
  - apply Hnm.
  - apply IH.
    rewrite add_comm in Hnm.
    rewrite <- plus_n_Sm in Hnm.
    rewrite <- plus_n_Sm in Hnm.
    rewrite add_comm in Hnm.
    inversion Hnm as [| k Hk Ek ].
    apply Hk.      
Qed.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (ev_plus_plus)

    This exercise can be completed without induction or case analysis.
    But, you will need a clever assertion and some tedious rewriting.
    Hint:  is [(n+m) + (n+p)] even? *)

Theorem ev_plus_plus : forall n m p,
  ev (n+m) -> ev (n+p) -> ev (m+p).
Proof.
  intros n m p Hnm Hnp.
  apply ev_ev__ev with (n+n).
  - (* ev (n+n+(m+p)), rewrite to ev ((n+p)+(n+m)) *)
    rewrite <- add_assoc.
    rewrite (add_assoc n m p).
    rewrite (add_comm (n+m) p).
    rewrite add_assoc.
    (* reduce to ev(n+p) and ev(n+m) *)
    apply ev_sum.
    apply Hnp.
    apply Hnm.
  - (* ev (n+n), reduce to ev (double n) *)
    rewrite <- double_plus.
    apply ev_double.
Qed.
(** [] *)

(* ################################################################# *)
(** * Inductive Relations *)

(** A proposition parameterized by a number (such as [ev])
    can be thought of as a _property_ -- i.e., it defines
    a subset of [nat], namely those numbers for which the proposition
    is provable.  In the same way, a two-argument proposition can be
    thought of as a _relation_ -- i.e., it defines a set of pairs for
    which the proposition is provable. *)

Module Playground.

(** ... And, just like properties, relations can be defined
    inductively.  One useful example is the "less than or equal to"
    relation on numbers. *)

(** The following definition says that there are two ways to
    show that one number is less than or equal to another: either
    observe that they are the same number, or, if the second has the
    form [S m], give evidence that the first is less than or equal to
    [m]. *)

Inductive le : nat -> nat -> Prop :=
  | le_n (n : nat)                : le n n
  | le_S (n m : nat) (H : le n m) : le n (S m).

Notation "n <= m" := (le n m).

(** Proofs of facts about [<=] using the constructors [le_n] and
    [le_S] follow the same patterns as proofs about properties, like
    [ev] above. We can [apply] the constructors to prove [<=]
    goals (e.g., to show that [3<=3] or [3<=6]), and we can use
    tactics like [inversion] to extract information from [<=]
    hypotheses in the context (e.g., to prove that [(2 <= 1) ->
    2+2=5].) *)

(** Here are some sanity checks on the definition.  (Notice that,
    although these are the same kind of simple "unit tests" as we gave
    for the testing functions we wrote in the first few lectures, we
    must construct their proofs explicitly -- [simpl] and
    [reflexivity] don't do the job, because the proofs aren't just a
    matter of simplifying computations.) *)

Theorem test_le1 :
  3 <= 3.
Proof.
  (* WORKED IN CLASS *)
  apply le_n.  Qed.

Theorem test_le2 :
  3 <= 6.
Proof.
  (* WORKED IN CLASS *)
  apply le_S. apply le_S. apply le_S. apply le_n.  Qed.

Theorem test_le3 :
  (2 <= 1) -> 2 + 2 = 5.
Proof.
  (* WORKED IN CLASS *)
  intros H. inversion H. inversion H2.  Qed.

(** The "strictly less than" relation [n < m] can now be defined
    in terms of [le]. *)

Definition lt (n m:nat) := le (S n) m.

Notation "m < n" := (lt m n).

End Playground.

(** Here are a few more simple relations on numbers: *)

Inductive square_of : nat -> nat -> Prop :=
  | sq n : square_of n (n * n).

Inductive next_nat : nat -> nat -> Prop :=
  | nn n : next_nat n (S n).

Inductive next_ev : nat -> nat -> Prop :=
  | ne_1 n (H: ev (S n))     : next_ev n (S n)
  | ne_2 n (H: ev (S (S n))) : next_ev n (S (S n)).

(** **** Exercise: 2 stars, standard, optional (total_relation)

    Define an inductive binary relation [total_relation] that holds
    between every pair of natural numbers. *)

(* The simplest solution *)
Inductive total_relation : nat -> nat -> Prop :=
| any n m : total_relation n m.

(* A more complicated solution *)
Inductive total_relation' : nat -> nat -> Prop :=
| start : total_relation' 0 0
| inc_left n m (H : total_relation' n m) : total_relation' (S n) m
| inr_right n m (H : total_relation' n m) : total_relation' n (S m).

(* FILL IN HERE

    [] *)

(** **** Exercise: 2 stars, standard, optional (empty_relation)

    Define an inductive binary relation [empty_relation] (on numbers)
    that never holds. *)

Inductive empty_relation : nat -> nat -> Prop := .

Inductive empty_relation' : nat -> nat -> Prop := 
| circular n m (H : empty_relation' n m) : empty_relation' n m.

(* FILL IN HERE

    [] *)

(** From the definition of [le], we can sketch the behaviors of
    [destruct], [inversion], and [induction] on a hypothesis [H]
    providing evidence of the form [le e1 e2].  Doing [destruct H]
    will generate two cases. In the first case, [e1 = e2], and it
    will replace instances of [e2] with [e1] in the goal and context.
    In the second case, [e2 = S n'] for some [n'] for which [le e1 n']
    holds, and it will replace instances of [e2] with [S n'].
    Doing [inversion H] will remove impossible cases and add generated
    equalities to the context for further use. Doing [induction H]
    will, in the second case, add the induction hypothesis that the
    goal holds when [e2] is replaced with [n']. *)

(** **** Exercise: 3 stars, standard, optional (le_exercises)

    Here are a number of facts about the [<=] and [<] relations that
    we are going to need later in the course.  The proofs make good
    practice exercises. *)

Lemma le_trans : forall m n o, m <= n -> n <= o -> m <= o.
Proof.
  intros m n o Hmn Hno.
  induction Hno as [ | o' _ IH ].
  - apply Hmn.
  - apply le_S. apply IH.
Qed.

Theorem O_le_n : forall n,
  0 <= n.
Proof.
  intros.
  induction n as [| n' IH ].
  - apply le_n.
  - apply le_S. apply IH. 
Qed.

Theorem n_le_m__Sn_le_Sm : forall n m,
  n <= m -> S n <= S m.
Proof.
  intros n m Hnm.
  induction Hnm as [| m' Hnm' IH ].
  - apply le_n.
  - apply le_S. apply IH.
Qed.

Theorem n_le_m__Sn_le_Sm' : forall n m,
  n <= m -> S n <= S m.
Proof.
  intros n m.
  generalize dependent n.
  induction m as [| m' IH ].
  - intros n H.
    inversion H.
    apply le_n.
  - intros n H.
    inversion H as [ HnSm | m'' Hnm' H' ].
    + apply le_n.
    + apply le_S. apply IH. apply Hnm'.
Qed.

Lemma n_le_m__predn_le_predm : forall n m, n <= m -> (pred n) <= (pred m).
Proof.
  intros n m H.
  induction H as [| m' E IH ].
  - apply le_n.
  - simpl.
    destruct m' as [| m''].
    + apply IH.
    + apply le_S. apply IH.
Qed.    

Theorem Sn_le_Sm__n_le_m : forall n m, S n <= S m -> n <= m.
Proof.
  intros n m H.
  replace (n) with (pred (S n)) by reflexivity.
  replace (m) with (pred (S m)) by reflexivity.
  apply n_le_m__predn_le_predm.
  apply H.
Qed.

Theorem Sn_le_Sm__n_le_m' : forall n m, S n <= S m -> n <= m.
Proof.
  intros n m H.
  inversion H as [ H' | m' H' E ].
  - apply le_n.
  - apply le_trans with (S n).
    + apply le_S. apply le_n.
    + apply H'.
Qed.

Theorem lt_ge_cases : forall n m,
  n < m \/ n >= m.
Proof.
  intros n m.
  generalize dependent n.
  induction m as [| m' IH ].
  - intros. right. apply O_le_n.
  - intros.
    destruct (IH n).
    + left. apply le_S. apply H.
    + inversion H as [ H' | n' H' ].
      * left. apply le_n.
      * right. apply n_le_m__Sn_le_Sm. apply H'.
Qed.

Theorem le_plus_l : forall a b,
  a <= a + b.
Proof.
  intros.
  induction b as [| b' IH ].
  - rewrite add_0_r. apply le_n.
  - rewrite <- plus_n_Sm. apply le_S. apply IH. 
Qed.

Theorem plus_le : forall n1 n2 m,
  n1 + n2 <= m ->
  n1 <= m /\ n2 <= m.
Proof.
 intros n1 n2 m H.
 induction H as [| m' Hm' IH ].
 - split.
   + apply le_plus_l.
   + rewrite add_comm. apply le_plus_l.
- destruct IH as [ IHn1 IHn2 ].
  split.
  + apply le_S. apply IHn1.
  + apply le_S. apply IHn2.
Qed.

(** Hint: the next one may be easiest to prove by induction on [n]. *)

Theorem add_le_cases : forall n m p q,
  n + m <= p + q -> n <= p \/ m <= q.
Proof.
  intros n.
  induction n as [| n' IH ].
  - intros. left. apply O_le_n.
  - intros m p q H.
    destruct p as [| p' ].
    + right.
      replace (0 + q) with q in H by reflexivity.
      destruct (plus_le (S n') m q H) as [ _ H' ].
      apply H'.
    + simpl in H.
      apply Sn_le_Sm__n_le_m in H.
      apply IH in H.
      destruct H.
      * left. apply n_le_m__Sn_le_Sm. apply H.
      * right. apply H.
Qed.

Theorem plus_le_compat_l : forall n m p,
  n <= m ->
  p + n <= p + m.
Proof.
  intros n m p H.
  induction H as [| m' H' IH ].
  - apply le_n.
  - rewrite <- plus_n_Sm.
    apply le_S.
    apply IH.
Qed.

Theorem plus_le_compat_r : forall n m p,
  n <= m ->
  n + p <= m + p.
Proof.
  intros n m p H.
  replace (n + p) with (p + n) by apply add_comm.
  replace (m + p) with (p + m) by apply add_comm.
  apply plus_le_compat_l.
  apply H.
Qed.

Theorem le_plus_trans : forall n m p,
  n <= m ->
  n <= m + p.
Proof.
  intros n m p H.
  apply le_trans with m.
  - apply H.
  - apply le_plus_l.
Qed.

Theorem n_lt_m__n_le_m : forall n m,
  n < m ->
  n <= m.
Proof.
  intros n m H.
  apply Sn_le_Sm__n_le_m.
  apply le_S.
  apply H.
Qed.

Theorem plus_lt : forall n1 n2 m,
  n1 + n2 < m ->
  n1 < m /\ n2 < m.
Proof.
  intros n1 n2 m H.
  unfold lt in H.
  split.
  - replace (S (n1 + n2)) with ((S n1) + n2) in H by reflexivity.
    apply plus_le in H.
    destruct H as [ H' _ ].
    apply H'.
  - rewrite plus_n_Sm in H.
    apply plus_le in H.
    destruct H as [ _ H' ].
    apply H'.
Qed.

Theorem leb_complete : forall n m,
  n <=? m = true -> n <= m.
Proof.
  intros n.
  induction n as [| n' IH ].
  - intros. apply O_le_n.
  - destruct m as [| m' ].
    + (* S n' <=? 0 = false *)
      discriminate.
    + simpl. intros H.
      apply n_le_m__Sn_le_Sm.
      apply IH. apply H.
Qed.

(** Hint: The next one may be easiest to prove by induction on [m]. *)

Lemma leb_step : forall n m, n <=? m = true -> n <=? S m = true.
Proof.
  intros n.
  induction n as [| n' IH ].
  - intros m _. reflexivity.
  - intros m H. destruct m as [| m' ].
    + (* H is inconsistent *) discriminate.
    + apply IH. apply H.
Qed. 

Theorem leb_correct : forall n m, n <= m -> n <=? m = true.
Proof.
  intros n m.
  generalize dependent n.
  induction m as [| m' IH ].
  - intros n H. inversion H. reflexivity.
  - intros n H. inversion H as [ H' | m'' H' E ].
    + apply leb_refl.
    + apply leb_step.
      apply IH. apply H'.
Qed.

Theorem leb_correct' : forall n m, n <= m -> n <=? m = true.
Proof.
  intros n m H.
  induction H as [| m' H' IH ].
  - apply leb_refl.
  - apply leb_step. apply IH. 
Qed.
(** Hint: The next one can easily be proved without using [induction]. *)

Theorem leb_true_trans : forall n m o,
  n <=? m = true -> m <=? o = true -> n <=? o = true.
Proof.
  intros n m o H1 H2.
  apply leb_correct.
  apply le_trans with m.
  - apply leb_complete. apply H1.
  - apply leb_complete. apply H2.
Qed.
(** [] *)

(** **** Exercise: 2 stars, standard, optional (leb_iff) *)
Theorem leb_iff : forall n m,
  n <=? m = true <-> n <= m.
Proof.
  intros. split.
  - apply leb_complete.
  - apply leb_correct. 
Qed.
(** [] *)

Module R.

(** **** Exercise: 3 stars, standard, especially useful (R_provability)

    We can define three-place relations, four-place relations,
    etc., in just the same way as binary relations.  For example,
    consider the following three-place relation on numbers: *)

Inductive R : nat -> nat -> nat -> Prop :=
  | c1                                     : R 0     0     0
  | c2 m n o (H : R m     n     o        ) : R (S m) n     (S o)
  | c3 m n o (H : R m     n     o        ) : R m     (S n) (S o)
  | c4 m n o (H : R (S m) (S n) (S (S o))) : R m     n     o
  | c5 m n o (H : R m     n     o        ) : R n     m     o
.

(** - Which of the following propositions are provable?
      - [R 1 1 2]
      - [R 2 2 6]

    - If we dropped constructor [c5] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer.

    - If we dropped constructor [c4] from the definition of [R],
      would the set of provable propositions change?  Briefly (1
      sentence) explain your answer. *)

(* FILL IN HERE *)

(*

  R 1 1 2   Provable
  R 2 2 6   Not Provable

  Constructors c1-c3 define a relation R(x, y, z) <=> x + y = z.

  Dropping c5 does not change the set of provable propositions, since it
  says that if R x y z, then R y x z. This does not add anything since
  addition is commutative.

  Dropping c4 does not change the set of provable propositions.
  Constructor c4 says that if R(x, y z) then R(x-1, y-1, z-2).
  Notice that x + y = z <=> x-1 + y-1 = z-2.

*)

(* Do not modify the following line: *)
Definition manual_grade_for_R_provability : option (nat*string) := None.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (R_fact)

    The relation [R] above actually encodes a familiar function.
    Figure out which function; then state and prove this equivalence
    in Coq. *)

Definition fR : nat -> nat -> nat := plus.

Theorem R_equiv_fR : forall m n o, R m n o <-> fR m n = o.
Proof.
  intros.
  split.
  - intros H.
    induction H as [| m' n' o' H' IH 
                    | m' n' o' H' IH 
                    | m' n' o' H' IH 
                    | m' n' o' H' IH ].
    + reflexivity.
    + simpl. f_equal. apply IH.
    + rewrite <- plus_n_Sm. f_equal. apply IH.
    + simpl in IH.
      rewrite <- plus_n_Sm in IH.
      injection IH as IH.
      apply IH.
    + rewrite add_comm. apply IH.
  - generalize dependent o.
    induction m as [| m' IH ].
    + simpl.
      induction n as [| n' IH ].
      * intros. rewrite <- H. apply c1.
      * intros o H. rewrite <- H. apply c3. apply IH. reflexivity.
    + simpl.
      intros [| o' ].
      * discriminate.
      * intros H.
        injection H as H.
        apply c2.
        apply IH.
        apply H.
Qed.

End R.

(** **** Exercise: 2 stars, advanced (subsequence)

    A list is a _subsequence_ of another list if all of the elements
    in the first list occur in the same order in the second list,
    possibly with some extra elements in between. For example,

      [1;2;3]

    is a subsequence of each of the lists

      [1;2;3]
      [1;1;1;2;2;3]
      [1;2;7;3]
      [5;6;1;9;9;2;7;3;8]

    but it is _not_ a subsequence of any of the lists

      [1;2]
      [1;3]
      [5;6;2;1;7;3;8].

    - Define an inductive proposition [subseq] on [list nat] that
      captures what it means to be a subsequence. (Hint: You'll need
      three cases.)

    - Prove [subseq_refl] that subsequence is reflexive, that is,
      any list is a subsequence of itself.

    - Prove [subseq_app] that for any lists [l1], [l2], and [l3],
      if [l1] is a subsequence of [l2], then [l1] is also a subsequence
      of [l2 ++ l3].

    - (Optional, harder) Prove [subseq_trans] that subsequence is
      transitive -- that is, if [l1] is a subsequence of [l2] and [l2]
      is a subsequence of [l3], then [l1] is a subsequence of [l3].
      Hint: choose your induction carefully! *)

Inductive subseq { X : Type } : list X -> list X -> Prop :=
| subseq_empty                          : subseq []     []
| subseq_step  x l l' (H : subseq l l') : subseq (x::l) (x::l')
| subseq_pad   x l l' (H : subseq l l') : subseq l      (x::l')
.

Theorem subseq_refl { X : Type }: forall (l : list X), subseq l l.
Proof.
  induction l as [| x l' IH ].
  - apply subseq_empty.
  - apply subseq_step. apply IH. 
Qed.

Lemma cons_app_distr : 
  forall {X : Type}, forall (x : X) l1 l2, (x :: l1) ++ l2 = x :: (l1 ++ l2).
Proof.
  intros X x l1.
  generalize dependent x.
  induction l1 as [| x l' IH ].
  - reflexivity.
  - intros y l2.
    replace ((y :: x :: l') ++ l2) with (y :: x :: l' ++ l2)
      by (reflexivity).
    rewrite IH.
    reflexivity.
Qed.

Lemma cons_app_distr' : 
  forall {X : Type}, forall (x : X) l1 l2, (x :: l1) ++ l2 = x :: (l1 ++ l2).
Proof.
  intros X x l1 l2.
  replace (x :: l1) with ([x] ++ l1) by reflexivity.
  replace (x :: (l1 ++ l2)) with ([x] ++ l1 ++ l2) by reflexivity.
  symmetry.
  apply app_assoc.
Qed.

Theorem subseq_app { X : Type } : forall (l1 l2 l3 : list X),
  subseq l1 l2 ->
  subseq l1 (l2 ++ l3).
Proof.
  intros l1 l2 l3 H.
  induction H as [| x l1' l2' H' IH | x l1' l2' H' IH ].
  - simpl.
    induction l3 as [| x l3' IH ].
    + apply subseq_empty.
    + apply subseq_pad. apply IH.
  - rewrite cons_app_distr.
    apply subseq_step.
    apply IH.
  - rewrite cons_app_distr.
    apply subseq_pad.
    apply IH.
Qed.

Lemma subseq_nil { X : Type }: forall (l : list X), subseq [] l.
Proof.
  induction l as [| x l' IH ].
  - apply subseq_empty.
  - apply subseq_pad. apply IH.  
Qed.

Lemma subseq_cons_split { X : Type } : 
  forall x (l1 l2 : list X), subseq (x::l1) l2 -> 
    exists l2' l2'', l2 = l2' ++ (x :: l2'') /\ subseq l1 l2''.
Proof.
  intros x l1 l2 H.
  induction l2 as [| y l2' IH ].
  - inversion H.
  - inversion H as [| z l1' l2'' H' | z l1' l2'' H' E1 E2 ].
    + exists []. exists l2'.
      split.
        { reflexivity. }
        { apply H'. }
    + destruct (IH H') as [ l2'_left [ l2'_right [ H1 H2 ]]].
      exists (y::l2'_left).
      exists l2'_right.
      split.
        { rewrite cons_app_distr. f_equal. apply H1. }
        { apply H2. }
Qed.

Theorem subseq_app_r { X : Type } : forall (l1 l2 l3 : list X),
  subseq l1 l2 ->
  subseq l1 (l3 ++ l2).
Proof.
  intros l1 l2 l3.
  generalize dependent l2.
  generalize dependent l1.
  induction l3 as [| x l3' IH ].
  - intros l1 l2 H. apply H.
  - intros l1 l2 H.
    rewrite cons_app_distr.
    apply subseq_pad.
    apply IH.
    apply H.  
Qed.

Lemma subseq_app_split { X : Type }:
  forall (l1 l2 l3 : list X), subseq (l1 ++ l2) l3 ->
    exists l3' l3'', l3 = l3' ++ l3'' /\ subseq l1 l3' /\ subseq l2 l3''.
Proof.
  induction l1 as [| x l1' IH ].
  - simpl.
    intros l2 l3 H.
    exists []. exists l3.
    split.
    + reflexivity.
    + split.
      { apply subseq_empty. }
      { apply H. }
  - intros l2 l3 H.
    rewrite cons_app_distr in H.
    destruct (subseq_cons_split x (l1'++l2) l3 H)
      as [ l3_pre [l3_post [ H1 H2 ]]].
    destruct (IH l2 l3_post H2) as [ l3' [ l3'' [ H3 [ H4 H5 ]]]].
    exists (l3_pre ++ (x :: l3')). exists l3''.
    split.
    + rewrite H1. rewrite H3.
      rewrite <- app_assoc.
      rewrite cons_app_distr.
      reflexivity.
    + split.
      * apply subseq_app_r. apply subseq_step. apply H4.
      * apply H5. 
Qed.

Theorem subseq_trans { X : Type }: forall (l1 l2 l3 : list X),
  subseq l1 l2 ->
  subseq l2 l3 ->
  subseq l1 l3.
Proof.
  induction l1 as [| x l1' IH ].
  - intros l2 l3 H1 H2. destruct l3 as [| z l3' ].
    + apply subseq_empty.
    + apply subseq_nil.
  - intros l2 l3 H1 H2.
    destruct  (subseq_cons_split x l1' l2 H1)
      as [ l2' [ l2'' [ H1' H1'' ] ] ].
    rewrite H1' in H2.
    destruct (subseq_app_split l2' (x::l2'') l3 H2)
      as [ l3' [l3'' [ H2' [ H2'' H2''' ]]]].
    destruct (subseq_cons_split x l2'' l3'' H2''')
      as [ l3''' [l3'''' [H3' H3'']]].
    rewrite H2'.
    rewrite H3'.
    rewrite app_assoc.
    apply subseq_app_r.
    apply subseq_step.
    apply IH with l2''.
    + apply H1''.
    + apply H3''.
Qed.

Theorem subseq_trans' { X : Type } : forall (l1 l2 l3 : list X),
  subseq l1 l2 ->
  subseq l2 l3 ->
  subseq l1 l3.
Proof.
  intros l1 l2 l3 H1 H2.
  generalize dependent H1.
  generalize dependent l1.
  induction H2 as [| x l2' l3' H IH | x l2' l3' H IH ].
  - intros l1 H. apply H.
  - intros l1 H'.
    inversion H' as [| y l1' l2'' H'' | y l1' l2'' H'' ].
    + apply subseq_step. apply IH. apply H''.
    + apply subseq_pad. apply IH. apply H''.
  - intros l1 H'.
    apply subseq_pad. apply IH. apply H'.
Qed.
(** [] *)

(** **** Exercise: 2 stars, standard, optional (R_provability2)

    Suppose we give Coq the following definition:

    Inductive R : nat -> list nat -> Prop :=
      | c1                    : R 0     []
      | c2 n l (H: R n     l) : R (S n) (n :: l)
      | c3 n l (H: R (S n) l) : R n     l.

    Which of the following propositions are provable?

    - [R 2 [1;0]]
    - [R 1 [1;2;1;0]]
    - [R 6 [3;2;1;0]]
*)

(* FILL IN HERE
    - [R 2 [1;0]]       Provable
    - [R 1 [1;2;1;0]]   Provable
    - [R 6 [3;2;1;0]]   Not Provable
  [] *)

(* ################################################################# *)
(** * Case Study: Regular Expressions *)

(** The [ev] property provides a simple example for
    illustrating inductive definitions and the basic techniques for
    reasoning about them, but it is not terribly exciting -- after
    all, it is equivalent to the two non-inductive definitions of
    evenness that we had already seen, and does not seem to offer any
    concrete benefit over them.

    To give a better sense of the power of inductive definitions, we
    now show how to use them to model a classic concept in computer
    science: _regular expressions_. *)

(** Regular expressions are a simple language for describing sets of
    strings.  Their syntax is defined as follows: *)

Inductive reg_exp (T : Type) : Type :=
  | EmptySet
  | EmptyStr
  | Char (t : T)
  | App (r1 r2 : reg_exp T)
  | Union (r1 r2 : reg_exp T)
  | Star (r : reg_exp T).

Arguments EmptySet {T}.
Arguments EmptyStr {T}.
Arguments Char {T} _.
Arguments App {T} _ _.
Arguments Union {T} _ _.
Arguments Star {T} _.

(** Note that this definition is _polymorphic_: Regular
    expressions in [reg_exp T] describe strings with characters drawn
    from [T] -- that is, lists of elements of [T].

    (We depart slightly from standard practice in that we do not
    require the type [T] to be finite.  This results in a somewhat
    different theory of regular expressions, but the difference is not
    significant for our purposes.) *)

(** We connect regular expressions and strings via the following
    rules, which define when a regular expression _matches_ some
    string:

      - The expression [EmptySet] does not match any string.

      - The expression [EmptyStr] matches the empty string [[]].

      - The expression [Char x] matches the one-character string [[x]].

      - If [re1] matches [s1], and [re2] matches [s2],
        then [App re1 re2] matches [s1 ++ s2].

      - If at least one of [re1] and [re2] matches [s],
        then [Union re1 re2] matches [s].

      - Finally, if we can write some string [s] as the concatenation
        of a sequence of strings [s = s_1 ++ ... ++ s_k], and the
        expression [re] matches each one of the strings [s_i],
        then [Star re] matches [s].

        In particular, the sequence of strings may be empty, so
        [Star re] always matches the empty string [[]] no matter what
        [re] is. *)

(** We can easily translate this informal definition into an
    [Inductive] one as follows.  We use the notation [s =~ re] in
    place of [exp_match s re].  (By "reserving" the notation before
    defining the [Inductive], we can use it in the definition.) *)

Reserved Notation "s =~ re" (at level 80).

Inductive exp_match {T} : list T -> reg_exp T -> Prop :=
  | MEmpty : [] =~ EmptyStr
  | MChar x : [x] =~ (Char x)
  | MApp s1 re1 s2 re2
             (H1 : s1 =~ re1)
             (H2 : s2 =~ re2)
           : (s1 ++ s2) =~ (App re1 re2)
  | MUnionL s1 re1 re2
                (H1 : s1 =~ re1)
              : s1 =~ (Union re1 re2)
  | MUnionR re1 s2 re2
                (H2 : s2 =~ re2)
              : s2 =~ (Union re1 re2)
  | MStar0 re : [] =~ (Star re)
  | MStarApp s1 s2 re
                 (H1 : s1 =~ re)
                 (H2 : s2 =~ (Star re))
               : (s1 ++ s2) =~ (Star re)
  where "s =~ re" := (exp_match s re).

(** Again, for readability, we can also display this definition using
    inference-rule notation. *)

(**

                          ----------------                    (MEmpty)
                           [] =~ EmptyStr

                          ---------------                      (MChar)
                           [x] =~ Char x

                       s1 =~ re1    s2 =~ re2
                      -------------------------                 (MApp)
                       s1 ++ s2 =~ App re1 re2

                              s1 =~ re1
                        ---------------------                (MUnionL)
                         s1 =~ Union re1 re2

                              s2 =~ re2
                        ---------------------                (MUnionR)
                         s2 =~ Union re1 re2

                          ---------------                     (MStar0)
                           [] =~ Star re

                      s1 =~ re    s2 =~ Star re
                     ---------------------------            (MStarApp)
                        s1 ++ s2 =~ Star re
*)

(** Notice that these rules are not _quite_ the same as the
    informal ones that we gave at the beginning of the section.
    First, we don't need to include a rule explicitly stating that no
    string matches [EmptySet]; we just don't happen to include any
    rule that would have the effect of some string matching
    [EmptySet].  (Indeed, the syntax of inductive definitions doesn't
    even _allow_ us to give such a "negative rule.")

    Second, the informal rules for [Union] and [Star] correspond
    to two constructors each: [MUnionL] / [MUnionR], and [MStar0] /
    [MStarApp].  The result is logically equivalent to the original
    rules but more convenient to use in Coq, since the recursive
    occurrences of [exp_match] are given as direct arguments to the
    constructors, making it easier to perform induction on evidence.
    (The [exp_match_ex1] and [exp_match_ex2] exercises below ask you
    to prove that the constructors given in the inductive declaration
    and the ones that would arise from a more literal transcription of
    the informal rules are indeed equivalent.)

    Let's illustrate these rules with a few examples. *)

Example reg_exp_ex1 : [1] =~ Char 1.
Proof.
  apply MChar.
Qed.

Example reg_exp_ex2 : [1; 2] =~ App (Char 1) (Char 2).
Proof.
  apply (MApp [1]).
  - apply MChar.
  - apply MChar.
Qed.

(** (Notice how the last example applies [MApp] to the string
    [[1]] directly.  Since the goal mentions [[1; 2]] instead of
    [[1] ++ [2]], Coq wouldn't be able to figure out how to split
    the string on its own.)

    Using [inversion], we can also show that certain strings do _not_
    match a regular expression: *)

Example reg_exp_ex3 : ~ ([1; 2] =~ Char 1).
Proof.
  intros H. inversion H.
Qed.

(** We can define helper functions for writing down regular
    expressions. The [reg_exp_of_list] function constructs a regular
    expression that matches exactly the list that it receives as an
    argument: *)

Fixpoint reg_exp_of_list {T} (l : list T) :=
  match l with
  | [] => EmptyStr
  | x :: l' => App (Char x) (reg_exp_of_list l')
  end.

Example reg_exp_ex4 : [1; 2; 3] =~ reg_exp_of_list [1; 2; 3].
Proof.
  simpl. apply (MApp [1]).
  { apply MChar. }
  apply (MApp [2]).
  { apply MChar. }
  apply (MApp [3]).
  { apply MChar. }
  apply MEmpty.
Qed.

(** We can also prove general facts about [exp_match].  For instance,
    the following lemma shows that every string [s] that matches [re]
    also matches [Star re]. *)

Lemma MStar1 :
  forall T s (re : reg_exp T) ,
    s =~ re ->
    s =~ Star re.
Proof.
  intros T s re H.
  rewrite <- (app_nil_r _ s).
  apply MStarApp.
  - apply H.
  - apply MStar0.
Qed.

(** (Note the use of [app_nil_r] to change the goal of the theorem to
    exactly the same shape expected by [MStarApp].) *)

(** **** Exercise: 3 stars, standard (exp_match_ex1)

    The following lemmas show that the informal matching rules given
    at the beginning of the chapter can be obtained from the formal
    inductive definition. *)

Lemma empty_is_empty : forall T (s : list T),
  ~ (s =~ EmptySet).
Proof.
  intros T s H.
  inversion H.
Qed.

Lemma MUnion' : forall T (s : list T) (re1 re2 : reg_exp T),
  s =~ re1 \/ s =~ re2 ->
  s =~ Union re1 re2.
Proof.
  intros T s re1 re2 [ H | H ].
  - apply MUnionL. apply H.
  - apply MUnionR. apply H.
Qed.

(** The next lemma is stated in terms of the [fold] function from the
    [Poly] chapter: If [ss : list (list T)] represents a sequence of
    strings [s1, ..., sn], then [fold app ss []] is the result of
    concatenating them all together. *)

Lemma MStar' : forall T (ss : list (list T)) (re : reg_exp T),
  (forall s, In s ss -> s =~ re) ->
  fold app ss [] =~ Star re.
Proof.
  intros T ss re.
  induction ss as [| s ss' IH ].
  - intros _.
    simpl.
    apply MStar0.
  - intros H.
    simpl.
    apply MStarApp.
    + apply H. simpl. left. reflexivity.
    + apply IH.
      intros s' Hs'.
      apply H.
      simpl. right. apply Hs'.     
Qed.
(** [] *)

(** **** Exercise: 4 stars, standard, optional (reg_exp_of_list_spec)

    Prove that [reg_exp_of_list] satisfies the following
    specification: *)

Lemma reg_exp_of_list_spec : forall T (s1 s2 : list T),
  s1 =~ reg_exp_of_list s2 <-> s1 = s2.
Proof.
  intros T s1 s2.
  generalize dependent s1.
  induction s2 as [| s s2' IH ].
  - intros s1. simpl.
    split.
    + intros H. inversion H. reflexivity.
    + intros H. rewrite H. apply MEmpty. 
  - intros s1. simpl.
    split.
    + intros H.
      inversion H as [| | s3 re1 s3' re2 H1 H2 E1 E2 | | | |].
      assert (H1' : s3 = [s]).
        { inversion H1. reflexivity. }
      rewrite H1'. simpl. f_equal.
      apply IH. apply H2.
    + intros H.
      replace (s1) with ([s] ++ s2') by (apply H).
      apply MApp.
      * apply MChar.
      * apply IH. reflexivity. 
Qed.
(** [] *)

(** Since the definition of [exp_match] has a recursive
    structure, we might expect that proofs involving regular
    expressions will often require induction on evidence. *)

(** For example, suppose that we wanted to prove the following
    intuitive result: If a regular expression [re] matches some string
    [s], then all elements of [s] must occur as character literals
    somewhere in [re].

    To state this theorem, we first define a function [re_chars] that
    lists all characters that occur in a regular expression: *)

Fixpoint re_chars {T} (re : reg_exp T) : list T :=
  match re with
  | EmptySet => []
  | EmptyStr => []
  | Char x => [x]
  | App re1 re2 => re_chars re1 ++ re_chars re2
  | Union re1 re2 => re_chars re1 ++ re_chars re2
  | Star re => re_chars re
  end.

(** We can then phrase our theorem as follows: *)

Theorem in_re_match : forall T (s : list T) (re : reg_exp T) (x : T),
  s =~ re ->
  In x s ->
  In x (re_chars re).
Proof.
  intros T s re x Hmatch Hin.
  induction Hmatch
    as [| x'
        | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
        | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
        | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2].
  (* WORKED IN CLASS *)
  - (* MEmpty *)
    simpl in Hin. destruct Hin.
  - (* MChar *)
    simpl. simpl in Hin.
    apply Hin.
  - (* MApp *)
    simpl.

(** Something interesting happens in the [MApp] case.  We obtain
    _two_ induction hypotheses: One that applies when [x] occurs in
    [s1] (which matches [re1]), and a second one that applies when [x]
    occurs in [s2] (which matches [re2]). *)

    rewrite In_app_iff in *.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      left. apply (IH1 Hin).
    + (* In x s2 *)
      right. apply (IH2 Hin).
  - (* MUnionL *)
    simpl. rewrite In_app_iff.
    left. apply (IH Hin).
  - (* MUnionR *)
    simpl. rewrite In_app_iff.
    right. apply (IH Hin).
  - (* MStar0 *)
    destruct Hin.
  - (* MStarApp *)
    simpl.

(** Here again we get two induction hypotheses, and they illustrate
    why we need induction on evidence for [exp_match], rather than
    induction on the regular expression [re]: The latter would only
    provide an induction hypothesis for strings that match [re], which
    would not allow us to reason about the case [In x s2]. *)

    rewrite In_app_iff in Hin.
    destruct Hin as [Hin | Hin].
    + (* In x s1 *)
      apply (IH1 Hin).
    + (* In x s2 *)
      apply (IH2 Hin).
Qed.

(** **** Exercise: 4 stars, standard (re_not_empty)

    Write a recursive function [re_not_empty] that tests whether a
    regular expression matches some string. Prove that your function
    is correct. *)

Fixpoint re_not_empty {T : Type} (re : reg_exp T) : bool :=
  match re with
  | EmptySet =>
    false
  | EmptyStr
  | Char _ =>
    true
  | App r1 r2 =>
    (re_not_empty r1) && (re_not_empty r2)
  | Union r1 r2 =>
    (re_not_empty r1) || (re_not_empty r2)
  | Star r =>
    true
  end.

Lemma re_not_empty_correct : forall T (re : reg_exp T),
  (exists s, s =~ re) <-> re_not_empty re = true.
Proof.
  intros T re.
  split.
  - intros [ s H ].
    induction H
      as [| x'
          | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
          | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
          | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2].
    + reflexivity.
    + reflexivity.
    + simpl.
      apply andb_true_iff.
      split.
        { apply IH1. }
        { apply IH2. }
    + simpl. apply orb_true_iff. left. apply IH.
    + simpl. apply orb_true_iff. right. apply IH.
    + reflexivity.
    + reflexivity. 
  - intros H.
    induction re as [| | c | r1 IH1 r2 IH2 | r1 IH1 r2 IH2 | r IH ].
    + discriminate.
    + exists []. apply MEmpty.
    + exists [c]. apply MChar.
    + simpl in H. apply andb_true_iff in H. destruct H as [ H1 H2 ].
      destruct (IH1 H1) as [s1 H1'].
      destruct (IH2 H2) as [s2 H2'].
      exists (s1 ++ s2).
      apply MApp.
        { apply H1'. }
        { apply H2'. }
    + simpl in H. apply orb_true_iff in H. destruct H as [ H | H ].
      * destruct (IH1 H) as [s H']. exists s. apply MUnionL. apply H'. 
      * destruct (IH2 H) as [s H']. exists s. apply MUnionR. apply H'.
    + exists []. apply MStar0.
Qed.
(** [] *)

(* ================================================================= *)
(** ** The [remember] Tactic *)

(** One potentially confusing feature of the [induction] tactic is
    that it will let you try to perform an induction over a term that
    isn't sufficiently general.  The effect of this is to lose
    information (much as [destruct] without an [eqn:] clause can do),
    and leave you unable to complete the proof.  Here's an example: *)

Lemma star_app: forall T (s1 s2 : list T) (re : reg_exp T),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.

(** Now, just doing an [inversion] on [H1] won't get us very far in
    the recursive cases. (Try it!). So we need induction (on
    evidence!). Here is a naive first attempt.

    (We can begin by generalizing [s2], since it's pretty clear that we
    are going to have to walk over both [s1] and [s2] in parallel.) *)

  generalize dependent s2.
  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** But now, although we get seven cases (as we would expect
    from the definition of [exp_match]), we have lost a very important
    bit of information from [H1]: the fact that [s1] matched something
    of the form [Star re].  This means that we have to give proofs for
    _all_ seven constructors of this definition, even though all but
    two of them ([MStar0] and [MStarApp]) are contradictory.  We can
    still get the proof to go through for a few constructors, such as
    [MEmpty]... *)

  - (* MEmpty *)
    simpl. intros s2 H. apply H.

(** ... but most cases get stuck.  For [MChar], for instance, we
    must show that

    s2 =~ Char x' -> x' :: s2 =~ Char x',

    which is clearly impossible. *)

  - (* MChar. *) intros s2 H. simpl. (* Stuck... *)
Abort.

(** The problem is that [induction] over a Prop hypothesis only works
    properly with hypotheses that are completely general, i.e., ones
    in which all the arguments are variables, as opposed to more
    complex expressions, such as [Star re].

    (In this respect, [induction] on evidence behaves more like
    [destruct]-without-[eqn:] than like [inversion].)

    An awkward way to solve this problem is "manually generalizing"
    over the problematic expressions by adding explicit equality
    hypotheses to the lemma: *)

Lemma star_app: forall T (s1 s2 : list T) (re re' : reg_exp T),
  re' = Star re ->
  s1 =~ re' ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.

(** We can now proceed by performing induction over evidence
    directly, because the argument to the first hypothesis is
    sufficiently general, which means that we can discharge most cases
    by inverting the [re' = Star re] equality in the context.

    This idiom is so common that Coq provides a
    tactic to automatically generate such equations for us, avoiding
    thus the need for changing the statements of our theorems. *)
Abort.

(** As we saw above, The tactic [remember e as x] causes Coq to (1)
    replace all occurrences of the expression [e] by the variable [x],
    and (2) add an equation [x = e] to the context.  Here's how we can
    use it to show the above result: *)

Lemma star_app: forall T (s1 s2 : list T) (re : reg_exp T),
  s1 =~ Star re ->
  s2 =~ Star re ->
  s1 ++ s2 =~ Star re.
Proof.
  intros T s1 s2 re H1.
  remember (Star re) as re'.

(** We now have [Heqre' : re' = Star re]. *)

  generalize dependent s2.
  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].

(** The [Heqre'] is contradictory in most cases, allowing us to
    conclude immediately. *)

  - (* MEmpty *)  discriminate.
  - (* MChar *)   discriminate.
  - (* MApp *)    discriminate.
  - (* MUnionL *) discriminate.
  - (* MUnionR *) discriminate.

(** The interesting cases are those that correspond to [Star].  Note
    that the induction hypothesis [IH2] on the [MStarApp] case
    mentions an additional premise [Star re'' = Star re], which
    results from the equality generated by [remember]. *)

  - (* MStar0 *)
    injection Heqre' as Heqre''. intros s H. apply H.

  - (* MStarApp *)
    injection Heqre' as Heqre''.
    intros s2 H1. rewrite <- app_assoc.
    apply MStarApp.
    + apply Hmatch1.
    + apply IH2.
      * rewrite Heqre''. reflexivity.
      * apply H1.
Qed.

(** **** Exercise: 4 stars, standard, optional (exp_match_ex2) *)

(** The [MStar''] lemma below (combined with its converse, the
    [MStar'] exercise above), shows that our definition of [exp_match]
    for [Star] is equivalent to the informal one given previously. *)

Lemma MStar'' : forall T (s : list T) (re : reg_exp T),
  s =~ Star re ->
  exists ss : list (list T),
    s = fold app ss []
    /\ forall s', In s' ss -> s' =~ re.
Proof.
  intros T s re H1.
  remember (Star re) as re' eqn:Heq.
  induction H1
    as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
        |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
        |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].
  - (* MEmpty *)  discriminate.
  - (* MChar *)   discriminate.
  - (* MApp *)    discriminate.
  - (* MUnionL *) discriminate.
  - (* MUnionR *) discriminate.
  - (* MStar0 *)
    exists []. simpl.
    split.
    + reflexivity.
    + intros s H. destruct H.
  - (* MStarApp *)
    destruct (IH2 Heq) as [ss [ H1 H2 ]].
    exists (s1::ss).
    split.
    + simpl. rewrite H1. reflexivity.
    + intros s Hs.
      simpl in Hs. destruct Hs as [ Hs | Hs ].
      * rewrite <- Hs. injection Heq as Heq. rewrite <- Heq. apply Hmatch1.
      * apply H2. apply Hs. 
Qed.
(** [] *)

(** **** Exercise: 5 stars, advanced (weak_pumping)

    One of the first really interesting theorems in the theory of
    regular expressions is the so-called _pumping lemma_, which
    states, informally, that any sufficiently long string [s] matching
    a regular expression [re] can be "pumped" by repeating some middle
    section of [s] an arbitrary number of times to produce a new
    string also matching [re].  (For the sake of simplicity in this
    exercise, we consider a slightly weaker theorem than is usually
    stated in courses on automata theory.)

    To get started, we need to define "sufficiently long."  Since we
    are working in a constructive logic, we actually need to be able
    to calculate, for each regular expression [re], the minimum length
    for strings [s] to guarantee "pumpability." *)

Module Pumping.

Fixpoint pumping_constant {T} (re : reg_exp T) : nat :=
  match re with
  | EmptySet => 1
  | EmptyStr => 1
  | Char _ => 2
  | App re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Union re1 re2 =>
      pumping_constant re1 + pumping_constant re2
  | Star r => pumping_constant r
  end.

(** You may find these lemmas about the pumping constant useful when
    proving the pumping lemma below. *)

Lemma pumping_constant_ge_1 :
  forall T (re : reg_exp T),
    pumping_constant re >= 1.
Proof.
  intros T re. induction re.
  - (* EmptySet *)
    apply le_n.
  - (* EmptyStr *)
    apply le_n.
  - (* Char *)
    apply le_S. apply le_n.
  - (* App *)
    simpl.
    apply le_trans with (n:=pumping_constant re1).
    apply IHre1. apply le_plus_l.
  - (* Union *)
    simpl.
    apply le_trans with (n:=pumping_constant re1).
    apply IHre1. apply le_plus_l.
  - (* Star *)
    simpl. apply IHre.
Qed.

Lemma pumping_constant_0_false :
  forall T (re : reg_exp T),
    pumping_constant re = 0 -> False.
Proof.
  intros T re H.
  assert (Hp1 : pumping_constant re >= 1).
  { apply pumping_constant_ge_1. }
  inversion Hp1 as [Hp1'| p Hp1' Hp1''].
  - rewrite H in Hp1'. discriminate Hp1'.
  - rewrite H in Hp1''. discriminate Hp1''.
Qed.

(** Next, it is useful to define an auxiliary function that repeats a
    string (appends it to itself) some number of times. *)

Fixpoint napp {T} (n : nat) (l : list T) : list T :=
  match n with
  | 0 => []
  | S n' => l ++ napp n' l
  end.

(** This auxiliary lemma might also be useful in your proof of the
    pumping lemma. *)

Lemma napp_plus: forall T (n m : nat) (l : list T),
  napp (n + m) l = napp n l ++ napp m l.
Proof.
  intros T n m l.
  induction n as [|n IHn].
  - reflexivity.
  - simpl. rewrite IHn, app_assoc. reflexivity.
Qed.

Lemma napp_star :
  forall T m s1 s2 (re : reg_exp T),
    s1 =~ re -> s2 =~ Star re ->
    napp m s1 ++ s2 =~ Star re.
Proof.
  intros T m s1 s2 re Hs1 Hs2.
  induction m.
  - simpl. apply Hs2.
  - simpl. rewrite <- app_assoc.
    apply MStarApp.
    + apply Hs1.
    + apply IHm.
Qed.

(** The (weak) pumping lemma itself says that, if [s =~ re] and if the
    length of [s] is at least the pumping constant of [re], then [s]
    can be split into three substrings [s1 ++ s2 ++ s3] in such a way
    that [s2] can be repeated any number of times and the result, when
    combined with [s1] and [s3] will still match [re].  Since [s2] is
    also guaranteed not to be the empty string, this gives us
    a (constructive!) way to generate strings matching [re] that are
    as long as we like. *)

Lemma weak_pumping : forall T (re : reg_exp T) s,
  s =~ re ->
  pumping_constant re <= length s ->
  exists s1 s2 s3,
    s = s1 ++ s2 ++ s3 /\
    s2 <> [] /\
    forall m, s1 ++ napp m s2 ++ s3 =~ re.

(** You are to fill in the proof. Several of the lemmas about
    [le] that were in an optional exercise earlier in this chapter
    may be useful. *)
Proof.
  intros T re s Hmatch.
  induction Hmatch
    as [ | x | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
       | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
       | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2 ].
  - (* MEmpty *)
    simpl. intros contra. inversion contra.
  - (* MChar *)
    simpl. intros H.
    inversion H as [| n contra E ]. inversion contra.
  - (* MApp *)
    simpl.
    intros H. rewrite app_length in H.
    apply add_le_cases in H. destruct H as [ H | H ].
    + destruct (IH1 H) as [ s3 [ s4 [ s5 [ H1 [ H2 H3 ]]]]].
      exists s3, s4 ,(s5++s2).
      split.
      * rewrite H1.
        rewrite <- app_assoc.
        replace ((s4 ++ s5) ++ s2) with (s4 ++ s5 ++ s2)
          by apply app_assoc.
        reflexivity.
      * split.
        ** apply H2.
        ** intros m.
           rewrite app_assoc.
           replace ((s3 ++ napp m s4) ++ s5 ++ s2) with
             (((s3 ++ napp m s4) ++ s5) ++ s2)
               by (symmetry; apply app_assoc).
           apply MApp.
             { rewrite <- app_assoc. apply H3. }
             { apply Hmatch2. }
    + destruct (IH2 H) as [ s3 [ s4 [ s5 [ H1 [ H2 H3 ]]]]].
      exists (s1++s3), s4, s5.
      split.
      * rewrite H1. rewrite <- app_assoc. reflexivity.
      * split.
        ** apply H2.
        ** intros m. rewrite <- app_assoc.
           apply MApp.
             { apply Hmatch1. }
             { apply H3. }
  - (* MUnionL *)
    simpl.
    intros H. apply plus_le in H. destruct H as [ H _ ].
    destruct (IH H) as [ s2 [ s3 [ s4 [ H1 [ H2 H3 ]]]]].
    exists s2, s3, s4.
    split.
      apply H1.
    split.
      apply H2.
      { intros m. apply MUnionL. apply H3. }
  - (* MUnionR *)
    simpl.
    intros H. apply plus_le in H. destruct H as [ _ H ].
    destruct (IH H) as [ s1 [ s3 [ s4 [ H1 [ H2 H3 ]]]]].
    exists s1, s3, s4.
    split.
      apply H1.
    split.
      apply H2.
      { intros m. apply MUnionR. apply H3. }
  - (* MStar0 *)
    simpl. intros H.
    inversion H as [ H' | ].
    apply pumping_constant_0_false in H' as contra.
    destruct contra.
  - (* MStarApp *)
    destruct s1 as [| c s2' ] eqn:Hs2.
    (* If s1 = [] *)
    + simpl. intros H. apply IH2. apply H.
    (* If s1 <> [], then we can take s1 as the string to be pumped *)
    + exists [], s1, s2. simpl.
      split.
        { rewrite Hs2. reflexivity. }
      split.
        { intros Hs1. rewrite Hs1 in Hs2. discriminate Hs2. }
        { intros m. apply napp_star.
          * rewrite Hs2. apply Hmatch1.
          * apply Hmatch2. }
Qed.
(** [] *)

(** **** Exercise: 5 stars, advanced, optional (pumping)

    Now here is the usual version of the pumping lemma. In addition to
    requiring that [s2 <> []], it also requires that [length s1 +
    length s2 <= pumping_constant re]. *)

(* The cases that don't simply follow immediately from the hypotheses in the
   contexts of the proof of the weak lemma are MApp and MStarApp.

   For MApp, we have to consider not the case split coming from the hypothesis
   that pumping_constant re1 + pumping_constant re2 <= length s1 + length s2,
   but instead use the knowledge that <= is a linear order (lt_ge_cases) to
   consider the cases:
     1. pumping_constant re1 < length s1; and
     2. pumping_constant re1 >= length s1,
          in which case we can derive pumping_constant re2 <= length s2 again
          from the knowlege that <= is a linear order by now relating
          (pumping_constant re2) and (length s2): we use the hypothesis that
          pumping_constant re1 + pumping_constant re2 <= length s1 + length s2
          along with the knowledge that < is irreflexive to rule out as
          inconsistent the case that length s2 < pumping_constant re2.
   Here I have proved and used an additional lemma (lt_irreflexive).
  
   Similarly, for MStarApp, we can no longer only split on whether s1 is empty
   or not. Instead in the case that s1 is not empty we have to then consider the
   subcases:
     1. pumping_constant (Star re) = pumping_constant re < length s1, and we can
        apply the IH on s1.
     2. pumping_contant (star re) >= length s1, in which case we can pump s1.
 *)

Lemma lt_irreflexive : forall n, ~ (n < n).
Proof.
  intros n H.
  induction n as [| n' IH ].
  - inversion H.
  - apply IH. apply Sn_le_Sm__n_le_m. apply H.
Qed.

Lemma not__n_le_m_and_m_lt_n : forall n m, ~ (n <= m /\ m < n).
Proof.
  intros n m [ H1 H2 ].
  induction H1 as [| m' Hm' IH1 ].
  - unfold lt in H2.
    induction n as [| n' IH2 ].
    + inversion H2.
    + apply IH2. apply Sn_le_Sm__n_le_m. apply H2.
  - apply IH1.
    unfold lt.
    transitivity (S (S m')).
      { apply le_S. apply le_n. }
      { apply H2. }
Qed.

(* This is actually a corollary of lt_irreflexive *)
Lemma not__n_le_m_and_m_lt_n' : forall n m, ~ (n <= m /\ m < n).
Proof.
  intros n m [ Hnm Hmn ].
  apply lt_irreflexive with m.
  unfold lt.
  transitivity n.
    { apply Hmn. }
    { apply Hnm. }
Qed.

Lemma plus_le_compat : forall n m p q, n <= m -> p <= q -> n + p <= m + q.
Proof.
  intros n m p q H1 H2.
  transitivity (m + p).
    { apply plus_le_compat_r. apply H1. }
    { apply plus_le_compat_l. apply H2. }
Qed.

Lemma pumping : forall T (re : reg_exp T) s,
  s =~ re ->
  pumping_constant re <= length s ->
  exists s1 s2 s3,
    s = s1 ++ s2 ++ s3 /\
    s2 <> [] /\
    length s1 + length s2 <= pumping_constant re /\
    forall m, s1 ++ napp m s2 ++ s3 =~ re.

(** You may want to copy your proof of weak_pumping below. *)
Proof.
  intros T re s Hmatch.
  induction Hmatch
    as [ | x | s1 re1 s2 re2 Hmatch1 IH1 Hmatch2 IH2
       | s1 re1 re2 Hmatch IH | re1 s2 re2 Hmatch IH
       | re | s1 s2 re Hmatch1 IH1 Hmatch2 IH2 ].
  - (* MEmpty *)
    simpl. intros contra. inversion contra.
    - (* MChar *)
    simpl. intros H.
    inversion H as [| n contra E ]. inversion contra.
  - (* MApp *)
    simpl.
    intros H. rewrite app_length in H.
    destruct (lt_ge_cases (pumping_constant re1) (length s1)) as [ Hs1 | Hs1 ].
    + (* pumping_constant re1 < length s1 *)
      assert (H' : pumping_constant re1 <= length s1).
        { transitivity (S (pumping_constant re1)).
            { apply le_S. apply le_n. }
            { apply Hs1. } }
      destruct (IH1 H') as [ s3 [ s4 [ s5 [ H1 [ H2 [ H3 H4 ]]]]]].
      exists s3, s4 ,(s5++s2).
      split.
      * rewrite H1.
        rewrite <- app_assoc.
        replace ((s4 ++ s5) ++ s2) with (s4 ++ s5 ++ s2)
          by apply app_assoc.
        reflexivity.
      * split.
        ** apply H2.
        ** split.
            *** transitivity (pumping_constant re1).
                  { apply H3. }
                  { apply le_plus_l. }
            *** intros m.
                rewrite app_assoc. rewrite app_assoc.
                apply MApp.
                  { rewrite <- app_assoc. apply H4. }
                  { apply Hmatch2. }
    + (* pumping_constant re1 >= length s1. *)
      (* We now consider how pumping_constant re2 and length s2 are related. *)
      destruct (lt_ge_cases (length s2) (pumping_constant re2)) as [ Hs2 | Hs2 ].
        (* length s2 < pumping_constant re2 leads to a contradiction *)
        exfalso.
        apply (lt_irreflexive (length s1 + length s2)). unfold lt.
        transitivity (pumping_constant re1 + pumping_constant re2).
          { rewrite plus_n_Sm. apply plus_le_compat. apply Hs1. apply Hs2. }
          { apply H. }
      (* So it must be that pumping_constant re2 <= length s2 *)
      destruct (IH2 Hs2) as [ s3 [ s4 [ s5 [ H1 [ H2 [ H3 H4 ]]]]]].
      exists (s1++s3), s4, s5.
      split.
      * rewrite H1. rewrite <- app_assoc. reflexivity.
      * split.
        ** apply H2.
        ** split.
           *** rewrite app_length. rewrite <- add_assoc.
               apply plus_le_compat. apply Hs1. apply H3.
           *** intros m. rewrite <- app_assoc.
               apply MApp.
                 { apply Hmatch1. }
                 { apply H4. }
  - (* MUnionL *)
    simpl.
    intros H. apply plus_le in H. destruct H as [ H _ ].
    destruct (IH H) as [ s2 [ s3 [ s4 [ H1 [ H2 [ H3 H4 ]]]]]].
    exists s2, s3, s4.
    split.
      { apply H1. }
    split.
      { apply H2. }
    split.
      { apply le_plus_trans. apply H3. }
      { intros m. apply MUnionL. apply H4. }
  - (* MUnionR *)
    simpl.
    intros H. apply plus_le in H. destruct H as [ _ H ].
    destruct (IH H) as [ s1 [ s3 [ s4 [ H1 [ H2 [ H3 H4 ]]]]]].
    exists s1, s3, s4.
    split.
      { apply H1. }
    split.
      { apply H2. }
    split.
      { replace (pumping_constant re1 + pumping_constant re2) 
          with (pumping_constant re2 + pumping_constant re1)
          by (apply add_comm).
        apply le_plus_trans. apply H3. }
      { intros m. apply MUnionR. apply H4. }
  - (* MStar0 *)
    simpl. intros H.
    inversion H as [ H' | ].
    apply pumping_constant_0_false in H' as contra.
    destruct contra.
  - (* MStarApp *)
    intros H.
    (* Proceed by case split on s1 as before. *)
    destruct s1 as [| c s2' ] eqn:Hs2.
    + (* s1 = [], and we can use IH2 *)
      simpl. apply IH2. apply H. 
    + (* s1 <> [], and we must now do a case split on whether or not
         pumping_constant (Star re) = pumping_constant re < length s1 *)
      destruct (lt_ge_cases (pumping_constant (Star re)) (length s1))
          as [ H' | H' ].
      * (* If pumping_constant (Star re) = pumping_constant re < length s1
           then we must use IH1. *)
        unfold lt in H'.
        assert (H'' : pumping_constant (Star re) <= length s1).
          { transitivity (S (pumping_constant (Star re))).
            apply le_S. apply le_n.
            apply H'. }
        rewrite Hs2 in H''.
        destruct (IH1 H'') as [ s0 [ s3 [ s4 [ H1 [ H2 [ H3 H4 ]]]]]].
        exists s0, s3, (s4++s2).
        split.
          { rewrite app_assoc. rewrite app_assoc. f_equal.
            rewrite <- app_assoc. apply H1. }
        split.
          { apply H2. }
        split.
          { apply H3. }
          { intros m. rewrite app_assoc. rewrite app_assoc.
            apply MStarApp.
              { rewrite <- app_assoc. apply H4. }
              { apply Hmatch2. } }
      * (* If pumping_constant (Star re) >= length s1 then we can simply pump s1. *)
        exists [], s1, s2. simpl.
        split.
          { rewrite Hs2. reflexivity. }
        split.
          { intros Hs1. rewrite Hs1 in Hs2. discriminate Hs2. }
        split.
          { apply H'. }
          { intros m. apply napp_star.
            * rewrite Hs2. apply Hmatch1.
            * apply Hmatch2. }
Qed.

End Pumping.
(** [] *)

(* ################################################################# *)
(** * Case Study: Improving Reflection *)

(** We've seen in the [Logic] chapter that we often need to
    relate boolean computations to statements in [Prop].  But
    performing this conversion as we did it there can result in
    tedious proof scripts.  Consider the proof of the following
    theorem: *)

Theorem filter_not_empty_In : forall n l,
  filter (fun x => n =? x) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (n =? m) eqn:H.
    + (* n =? m = true *)
      intros _. rewrite eqb_eq in H. rewrite H.
      left. reflexivity.
    + (* n =? m = false *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** In the first branch after [destruct], we explicitly apply
    the [eqb_eq] lemma to the equation generated by
    destructing [n =? m], to convert the assumption [n =? m
    = true] into the assumption [n = m]; then we had to [rewrite]
    using this assumption to complete the case. *)

(** We can streamline this by defining an inductive proposition that
    yields a better case-analysis principle for [n =? m].  Instead of
    generating an equation such as [(n =? m) = true], which is
    generally not directly useful, this principle gives us right away
    the assumption we really need: [n = m].

    Following the terminology introduced in [Logic], we call
    this the "reflection principle for equality (between numbers),"
    and we say that the boolean [n =? m] is _reflected in_ the
    proposition [n = m]. *)

Inductive reflect (P : Prop) : bool -> Prop :=
  | ReflectT (H :   P) : reflect P true
  | ReflectF (H : ~ P) : reflect P false.

(** The [reflect] property takes two arguments: a proposition
    [P] and a boolean [b].  Intuitively, it states that the property
    [P] is _reflected_ in (i.e., equivalent to) the boolean [b]: that
    is, [P] holds if and only if [b = true].  To see this, notice
    that, by definition, the only way we can produce evidence for
    [reflect P true] is by showing [P] and then using the [ReflectT]
    constructor.  If we invert this statement, this means that it
    should be possible to extract evidence for [P] from a proof of
    [reflect P true].  Similarly, the only way to show [reflect P
    false] is by combining evidence for [~ P] with the [ReflectF]
    constructor. *)

(** To put this observation to work, we first prove that the
    statements [P <-> b = true] and [reflect P b] are indeed
    equivalent.  First, the left-to-right implication: *)

Theorem iff_reflect : forall P b, (P <-> b = true) -> reflect P b.
Proof.
  (* WORKED IN CLASS *)
  intros P b H. destruct b eqn:Eb.
  - apply ReflectT. rewrite H. reflexivity.
  - apply ReflectF. rewrite H. intros H'. discriminate.
Qed.

(** Now you prove the right-to-left implication: *)

(** **** Exercise: 2 stars, standard, especially useful (reflect_iff) *)
Theorem reflect_iff : forall P b, reflect P b -> (P <-> b = true).
Proof.
  intros P b H.
  split.
  - inversion H as [ H' eqnb | H' eqnb ].
    + intros _. reflexivity.
    + intros HP. exfalso. apply H'. apply HP.
  - intros Hb. rewrite Hb in H.
    inversion H as [ HP | ]. apply HP.
Qed.
(** [] *)

(** The advantage of [reflect] over the normal "if and only if"
    connective is that, by destructing a hypothesis or lemma of the
    form [reflect P b], we can perform case analysis on [b] while at
    the same time generating appropriate hypothesis in the two
    branches ([P] in the first subgoal and [~ P] in the second). *)

Lemma eqbP : forall n m, reflect (n = m) (n =? m).
Proof.
  intros n m. apply iff_reflect. rewrite eqb_eq. reflexivity.
Qed.

(** A smoother proof of [filter_not_empty_In] now goes as follows.
    Notice how the calls to [destruct] and [rewrite] are combined into a
    single call to [destruct]. *)

(** (To see this clearly, look at the two proofs of
    [filter_not_empty_In] with Coq and observe the differences in
    proof state at the beginning of the first case of the
    [destruct].) *)

Theorem filter_not_empty_In' : forall n l,
  filter (fun x => n =? x) l <> [] ->
  In n l.
Proof.
  intros n l. induction l as [|m l' IHl'].
  - (* l = [] *)
    simpl. intros H. apply H. reflexivity.
  - (* l = m :: l' *)
    simpl. destruct (eqbP n m) as [H | H].
    + (* n = m *)
      intros _. rewrite H. left. reflexivity.
    + (* n <> m *)
      intros H'. right. apply IHl'. apply H'.
Qed.

(** **** Exercise: 3 stars, standard, especially useful (eqbP_practice)

    Use [eqbP] as above to prove the following: *)

Fixpoint count n l :=
  match l with
  | [] => 0
  | m :: l' => (if n =? m then 1 else 0) + count n l'
  end.

Theorem eqbP_practice : forall n l,
  count n l = 0 -> ~(In n l).
Proof.
  intros n.
  induction l as [| m l' IH ].
  - simpl. intros _ HFalse. apply HFalse.
  - simpl. destruct (eqbP n m) as [H | H].
    + simpl. intros contra. discriminate contra.
    + simpl. intros H' [ Hmn | Hl' ].
      * apply H. symmetry. apply Hmn.
      * apply IH. apply H'. apply Hl'. 
Qed.
(** [] *)

(** This small example shows reflection giving us a small gain in
    convenience; in larger developments, using [reflect] consistently
    can often lead to noticeably shorter and clearer proof scripts.
    We'll see many more examples in later chapters and in _Programming
    Language Foundations_.

    The use of the [reflect] property has been popularized by
    _SSReflect_, a Coq library that has been used to formalize
    important results in mathematics, including as the 4-color theorem
    and the Feit-Thompson theorem.  The name SSReflect stands for
    _small-scale reflection_, i.e., the pervasive use of reflection to
    simplify small proof steps with boolean computations. *)

(* ################################################################# *)
(** * Additional Exercises *)

(** **** Exercise: 3 stars, standard, especially useful (nostutter_defn)

    Formulating inductive definitions of properties is an important
    skill you'll need in this course.  Try to solve this exercise
    without any help at all.

    We say that a list "stutters" if it repeats the same element
    consecutively.  (This is different from not containing duplicates:
    the sequence [[1;4;1]] repeats the element [1] but does not
    stutter.)  The property "[nostutter mylist]" means that [mylist]
    does not stutter.  Formulate an inductive definition for
    [nostutter]. *)

Inductive nostutter {X:Type} : list X -> Prop :=
| Empty             : nostutter []
| Singleton (x : X) : nostutter [x]
| Cons (x y : X) (l : list X) (H : x <> y) (H' : nostutter(y::l))
    : nostutter(x::y::l).

    (** Make sure each of these tests succeeds, but feel free to change
    the suggested proof (in comments) if the given one doesn't work
    for you.  Your definition might be different from ours and still
    be correct, in which case the examples might need a different
    proof.  (You'll notice that the suggested proofs use a number of
    tactics we haven't talked about, to make them more robust to
    different possible ways of defining [nostutter].  You can probably
    just uncomment and use them as-is, but you can also prove each
    example with more basic tactics.)  *)

Example test_nostutter_1: nostutter [3;1;4;1;5;6].
Proof.
  repeat constructor; apply eqb_neq; auto.
Qed.

Example test_nostutter_2:  nostutter (@nil nat).
Proof.
  repeat constructor; apply eqb_neq; auto.
Qed.

Example test_nostutter_3:  nostutter [5].
Proof.
  repeat constructor; apply eqb_neq; auto.
Qed.

Example test_nostutter_4:  not (nostutter [3;1;1;4]).
Proof.
  intro.
  repeat match goal with
    h: nostutter _ |- _ => inversion h; clear h; subst
  end.
  contradiction; auto.
Qed.

(* Do not modify the following line: *)
Definition manual_grade_for_nostutter : option (nat*string) := None.
(** [] *)

(** **** Exercise: 4 stars, advanced (filter_challenge)

    Let's prove that our definition of [filter] from the [Poly]
    chapter matches an abstract specification.  Here is the
    specification, written out informally in English:

    A list [l] is an "in-order merge" of [l1] and [l2] if it contains
    all the same elements as [l1] and [l2], in the same order as [l1]
    and [l2], but possibly interleaved.  For example,

    [1;4;6;2;3]

    is an in-order merge of

    [1;6;2]

    and

    [4;3].

    Now, suppose we have a set [X], a function [test: X->bool], and a
    list [l] of type [list X].  Suppose further that [l] is an
    in-order merge of two lists, [l1] and [l2], such that every item
    in [l1] satisfies [test] and no item in [l2] satisfies test.  Then
    [filter test l = l1].

    Translate this specification into a Coq theorem and prove
    it.  (You'll need to begin by defining what it means for one list
    to be a merge of two others.  Do this with an inductive relation,
    not a [Fixpoint].)  *)

Inductive inorder_merge {X : Type} : list X -> list X -> list X -> Prop :=
| EmptyLeft (l : list X)  : inorder_merge [] l  l
| EmptyRight (l : list X) : inorder_merge l  [] l
| StepLeft (x : X) (l1 l2 l3 : list X) (H : inorder_merge l1 l2 l3)
    : inorder_merge (x::l1) l2 (x::l3)
| StepRight (x : X) (l1 l2 l3 : list X) (H : inorder_merge l1 l2 l3)
    : inorder_merge l1 (x::l2) (x::l3).

Theorem filter_inorder_merge {X : Type} :
  forall (l l1 l2 : list X) (test : X -> bool),
    (forall x, In x l1 -> test x = true) ->
      (forall x, In x l2 -> test x = false) ->
        inorder_merge l1 l2 l -> filter test l = l1.
Proof.
  intros l l1 l2 test Hl1 Hl2 Hmerge.
  induction Hmerge as [| | x l1' l2' l' H IH | x l1' l2' l' H IH ].
  - induction l as [| x l' IH ].
    + reflexivity.
    + assert (H : test x = false).
        { apply Hl2. simpl. left. reflexivity. } 
      simpl. rewrite H. apply IH.
      intros x' Hx'. apply Hl2. simpl. right. apply Hx'.
  - induction l as [| x l' IH ].
    + reflexivity.
    + assert (H : test x = true).
        { apply Hl1. simpl. left. reflexivity. }
      simpl. rewrite H. f_equal. apply IH.
      intros x' Hx'. apply Hl1. simpl. right. apply Hx'.
  - assert (H' : test x = true).
      { apply Hl1. simpl. left. reflexivity. }
    simpl. rewrite H'. f_equal.
    apply IH.
      { intros x' Hx'. apply Hl1. simpl. right. apply Hx'. }
      { apply Hl2. }
  - assert (H' : test x = false).
      { apply Hl2. simpl. left. reflexivity. } 
    simpl. rewrite H'. apply IH.
      { apply Hl1. }
      { intros x' Hx'. apply Hl2. simpl. right. apply Hx'. }
Qed.

(* Do not modify the following line: *)
Definition manual_grade_for_filter_challenge : option (nat*string) := None.
(** [] *)

(** **** Exercise: 5 stars, advanced, optional (filter_challenge_2)

    A different way to characterize the behavior of [filter] goes like
    this: Among all subsequences of [l] with the property that [test]
    evaluates to [true] on all their members, [filter test l] is the
    longest.  Formalize this claim and prove it. *)

Definition satisfying_subseq { X : Type } (test : X -> bool) (l l' : list X ) : Prop :=
  subseq l' l /\ (forall x, In x l' -> test x = true).

Theorem filter_contains_all_subseqs { X : Type } :
  forall (l : list X) (test : X -> bool),
    satisfying_subseq test l (filter test l)
      /\
    (forall l', satisfying_subseq test l l' -> subseq l' (filter test l)).
Proof.
  intros.
  split.
  - unfold satisfying_subseq.
    split.
    + induction l as [| x l' IH ].
      * simpl. apply subseq_empty.
      * simpl.
        destruct (test x).
          { apply subseq_step. apply IH. }
          { apply subseq_pad. apply IH. }
    + induction l as [| x l' IH ].
      * simpl. intros x' contra. exfalso. apply contra.
      * intros x'. simpl. destruct (test x) eqn:Htest.
          { simpl. intros [ H | H ].
              { rewrite <- H. apply Htest. }
              { apply IH. apply H. } }
          { apply IH. }
  - induction l as [| x l' IH ].
    + unfold satisfying_subseq.
      intros l'' [ H1 H2 ].
      simpl. apply H1.
    + intros l'' [ H1 H2 ]. 
      simpl. destruct (test x) eqn:Htest.
      * inversion H1 as [| x' l''_tail l'2 Htail Eq_head Eq_tail
                         | x' l''_tail l'2 Htail Eq_head Eq_tail ].
        ** apply subseq_step. apply IH.
            unfold satisfying_subseq.
            split.
              { apply Htail. }
              { intros y Hy.
                apply H2. rewrite <- Eq_head. simpl.
                right. apply Hy. }
        ** apply subseq_pad. apply IH.
            unfold satisfying_subseq.
            split.
              { apply Htail. }
              { intros y Hy. apply H2. apply Hy. }
      * apply IH.
        unfold satisfying_subseq. split.
        ** inversion H1 as [| x' l''_tail l'2 Htail Eq Eq_head
                            | x' l''_tail l'2 Htail Eq_head Eq_tail ].
           *** assert (H' : In x l'').
                 { rewrite <- Eq. simpl. left. apply Eq_head. }
                 apply H2 in H' as contra.
                 rewrite Htest in contra.
                 discriminate.
           *** apply Htail.
        ** apply H2.
Qed.

Lemma subseq_l { X : Type } : forall (x : X) (l l' : list X),
    subseq (x::l') l -> subseq l' l.
Proof.
  intros x l l' H.
  generalize dependent l'.
  induction l as [| x' l'' IH ].
  - intros l H. inversion H.
  - intros l' H.
    inversion H as [| y l1 l2 H' | y l1 l2 H' ].
    + apply subseq_pad. apply H'.
    + apply subseq_pad. apply IH. apply H'.
Qed.

Lemma subseq_length { X : Type } :
    forall (l l' : list X), subseq l' l -> length l' <= length l.
Proof.
  intros l l'.
  generalize dependent l.
  induction l' as [| x l'' IH ].
  - simpl. intros. apply O_le_n.
  - intros l H.
    inversion H as [| x' l''2 l_tail Htail E1 E2 
                    | x' l''2 l_tail Htail E1 E2 ].
    + simpl. apply n_le_m__Sn_le_Sm. apply IH. apply Htail.
    + simpl. apply n_le_m__Sn_le_Sm. apply IH.
      apply subseq_l with x. apply Htail.
Qed.

Theorem filter_is_longest_subseq { X : Type } :
  forall (l : list X) (test : X -> bool),
    satisfying_subseq test l (filter test l)
      /\
    (forall l',
      satisfying_subseq test l l' -> length l' <= length (filter test l)).
Proof.
  intros l test.
  split.
  - destruct (filter_contains_all_subseqs l test) as [ H _ ].
    apply H.
  - intros l' H. apply subseq_length.
    destruct (filter_contains_all_subseqs l test) as [ _ H' ].
    apply H'. apply H.
Qed.

(* FILL IN HERE

    [] *)

(** **** Exercise: 4 stars, standard, optional (palindromes)

    A palindrome is a sequence that reads the same backwards as
    forwards.

    - Define an inductive proposition [pal] on [list X] that
      captures what it means to be a palindrome. (Hint: You'll need
      three cases.  Your definition should be based on the structure
      of the list; just having a single constructor like

        c : forall l, l = rev l -> pal l

      may seem obvious, but will not work very well.)

    - Prove ([pal_app_rev]) that

       forall l, pal (l ++ rev l).

    - Prove ([pal_rev] that)

       forall l, pal l -> l = rev l.
*)

(* FILL IN HERE *)

Inductive pal { X : Type } : list X -> Prop :=
| pal_empty                                      : pal []
| pal_singleton (x : X)                          : pal [x]
| pal_step      (x : X) (l : list X) (H : pal l) : pal (x :: (l ++ [x]))
.

Theorem pal_app_rev { X : Type }: forall (l : list X), pal (l ++ rev l).
Proof.
  induction l as [| x l' IH ].
  - simpl. apply pal_empty.
  - simpl. rewrite app_assoc. apply pal_step. apply IH.
Qed.

Theorem pal_rev { X : Type } : forall (l : list X), pal l -> l = rev l.
Proof.
  intros l Hpal.
  induction Hpal as [| x | x l' Hl' IH ].
  - reflexivity.
  - reflexivity.
  - simpl.
    rewrite rev_app_distr. rewrite <- app_assoc. rewrite <- IH.
    reflexivity.
Qed.

(* Do not modify the following line: *)
Definition manual_grade_for_pal_pal_app_rev_pal_rev : option (nat*string) := None.
(** [] *)

(** **** Exercise: 5 stars, standard, optional (palindrome_converse)

    Again, the converse direction is significantly more difficult, due
    to the lack of evidence.  Using your definition of [pal] from the
    previous exercise, prove that

     forall l, l = rev l -> pal l.
*)

Lemma cons_app_exchange { X : Type } :
  forall (x : X) (l : list X), exists l' y, x :: l = l' ++ [y].
Proof.
  intros x l.
  generalize dependent x.
  induction l as [| y l' IH ].
  - intros x. exists [], x. reflexivity.
  - intros x.
    destruct (IH y) as [l'' [ z H ]].
    exists (x::l''), z.
    simpl. f_equal. apply H. 
Qed.

(* In fact, we only need the left hand consequent of this implication *)
Lemma subseq_closed_l { X : Type } :
  forall (l1 l2 l3 : list X),
    subseq (l1 ++ l2) l3 -> subseq l1 l3 /\ subseq l2 l3.
Proof.
  intros l1 l2 l3 H.
  destruct (subseq_app_split l1 l2 l3 H) as [ l3' [ l3'' [ H1 [ H2 H3 ]]]].
  rewrite H1.
  split.
  - apply subseq_app. apply H2.
  - apply subseq_app_r. apply H3.
Qed.

Theorem rev_pal_strong { X : Type } :
  forall (l l' : list X), subseq l' l /\ l' = rev l' -> pal l'.
Proof.
  induction l as [| x l' IH ].
  - intros l' [ H _ ]. inversion H. apply pal_empty.
  - intros l'' [ H1 H2 ].
    inversion H1 as [| y l1 l2 H Hl' Hhead | ].
    + destruct l1 as [| z l''' ] eqn:Htail.
      * apply pal_singleton.
      * rewrite <- Htail in *.
        symmetry in Hl'. rewrite Hhead in Hl'.
        (* l1 <> [], so exists x' l1', l1 = l1' ++ [x'] *)
        destruct (cons_app_exchange z l''') as [ l1' [ x' Htail' ]].
        rewrite Htail' in Htail.
        (* x :: l1 = rev (x :: l1) *)
        rewrite Hl' in H2.
        (* so x :: l1' ++ [x'] = rev (l1' ++ [x']) ++ [x] *)
        rewrite Htail in H2. simpl in H2.
        (* so x :: l1' ++ [x'] = (x' :: rev l1') ++ [x] *)
        rewrite rev_app_distr in H2. rewrite <- app_assoc in H2. simpl in H2.
        (* so x = x' *)
        injection H2 as Hx H2'.
        (* and thence l1' = rev l1' *)
        rewrite <- Hx in H2'.
        (* Could use the app_injective_l lemma below, but for the specific case
           we need here, it is enough to reason with rev and injectivity of
           cons. *)
        assert (H2'' : rev(l1' ++ [x]) = rev(rev l1' ++ [x])).
          { f_equal. apply H2'. }
        rewrite rev_app_distr in H2''. rewrite rev_app_distr in H2''.
        simpl in H2''. injection H2'' as H2''. rewrite rev_involutive in H2''.
        symmetry in H2''.
        (* l1 = l1' ++ [x] is a subsequence of l', thus l1' is also a subsequence of l' *)
        rewrite Htail in H.
        destruct (subseq_closed_l l1' [x'] l' H) as [ H' _ ].
        (* we can conlude with the IH *)
        rewrite Htail. rewrite <- Hx. apply pal_step.
        apply IH. split.
          { apply H'. }
          { apply H2''. }
    + apply IH.
      split.
        { apply H. }
        { apply H2. }
Qed.

Theorem rev_pal { X : Type } : forall (l : list X), l = rev l -> pal l.
Proof.
  intros l H.
  apply (rev_pal_strong l l).
  split.
  - apply subseq_refl.
  - apply H. 
Qed.

(* The following are auxiliary results that I thought were necessary when
   developing the proof of rev_pal.

   app_injective_l is a general form of the more specific result I needed that
      l1 ++ [x] = l2 ++ [x] -> l1 = l2
   This more specific results can be proved using rev, and injectivity of cons.
 *)

Lemma cons_not_circular { X : Type } : forall (x : X) (l : list X), x::l <> l.
Proof.
  intros x l H.
  induction l as [| x' l' IH ].
  - discriminate H.
  - injection H as Hx Htail. apply IH. rewrite Hx. apply Htail.
Qed.

(* cons injective: l = l' -> x::l = x::l' *)
Lemma cons_inj { X : Type } : 
  forall (x : X) (l l' : list X), l = l' -> x::l = x::l'.
Proof.
  intros x l l' H.
  f_equal. apply H.
Qed.

(* by contrapositive: x::l <> x::l' -> l <> l' *)
Lemma cons_inj2 { X : Type } : 
  forall (x : X) (l l' : list X), x::l <> x::l' -> l <> l'.
Proof.
  intros x l l'.
  apply (contrapositive (l = l') (x::l = x::l')).
  apply cons_inj.
Qed.

Lemma cons_inj3 { X : Type } : 
  forall (x : X) (l l' : list X), l <> l' -> x::l <> x::l'.
Proof.
  intros x l l' H1 H2.
  apply H1.
  injection H2.
  intros H. apply H.
Qed.

Lemma cons_inj4 { X : Type } : 
  forall (x y : X) (l : list X), x <> y -> x::l <> y::l.
Proof.
  intros x y l H1 H2.
  apply H1.
  injection H2.
  intro H. apply H.
Qed.

Lemma lists_not_circular { X : Type } : 
  forall (l l' : list X), l <> [] -> l++l' <> l'.
Proof.
  induction l as [| x l'' IH ].
  - intros l H H'. apply H. reflexivity.
  - destruct l'' as [| y l''' ] eqn:H.
    + intros. simpl. apply cons_not_circular.
    + rewrite <- H in *.
      intros l _ contra.
      destruct l as [| z l' ].
      * discriminate contra.
      * (* apply IH *)
Abort.

Lemma lists_not_circular { X : Type } : 
  forall (l l' : list X), l <> [] -> l++l' <> l'.
Proof.
  intros l l'.
  generalize dependent l.
  induction l' as [| x l'' IH ].
  - intros l H contra.
    rewrite app_nil_r in contra.
    apply H. apply contra.
  - intros l H contra.
    destruct l as [| y l' ].
    + apply H. reflexivity.
    + apply IH with (l' ++ [x]).
      * intros contra'. destruct l'.
          { discriminate contra'. }
          { discriminate contra'. }
      * rewrite cons_app_distr in contra.
        injection contra as _ contra.
        rewrite <- app_assoc. apply contra.
Qed.  

Lemma app_injective_l { X : Type } :
  forall (l1 l2 l3 : list X), l1 ++ l3 = l2 ++ l3 -> l1 = l2.
Proof.
  intros l1 l2 l3.
  generalize dependent l2.
  generalize dependent l1.
  induction l3 as [| x l3' IH ].
  - intros l1 l2. rewrite app_nil_r. rewrite app_nil_r. intros H. apply H.
  - intros l1 l2. 
    replace (x :: l3') with ([x] ++ l3') by reflexivity.
    rewrite app_assoc. rewrite app_assoc.
    intros H.
    apply IH. 
Abort.

Lemma app_injective_l { X : Type } :
  forall (l1 l2 l3 : list X), l1 ++ l3 = l2 ++ l3 -> l1 = l2.
Proof.
  induction l1 as [| x l1' IH ].
  - intros l2. simpl.
    induction l2.
    + intros. reflexivity.
    + induction l3 as [| y l3' ].
      * intros H. discriminate H.
      * intros H. exfalso.
        apply (lists_not_circular (l2 ++ [y]) (l3')).
        ** intros contra.
           destruct l2.
              { discriminate contra. }
              { discriminate contra. }
        ** rewrite <- app_assoc. simpl. symmetry. injection H as _ H. apply H.
  - intros l2 l3 H.
    destruct l2 as [| y l2' ] eqn:Hl2.
    + exfalso.
      apply (lists_not_circular (x::l1') l3).
        { intros contra. discriminate contra. }
        { apply H. }
    + rewrite cons_app_distr in H. rewrite cons_app_distr in H.
      injection H as H1 H2.
      rewrite H1. f_equal.
      apply IH with l3. apply H2.
Qed. 

Lemma subseq_closed_step { X : Type } :
  forall (x : X) (l1 l2 : list X), subseq (x :: l1) (x :: l2) -> subseq l1 l2.
Proof.
  intros x l1 l2 H.
  destruct (subseq_cons_split x l1 (x::l2) H) as [l2' [ l2'' [ H1 H2 ]]].
  destruct l2' as [| y l3 ].
  - simpl in H1. injection H1 as H3. rewrite H3. apply H2.
  - simpl in H1. injection H1 as _ H3. rewrite H3.
    replace (x::l2'') with ([x] ++ l2'') by reflexivity.
    rewrite app_assoc.
    apply subseq_app_r.
    apply H2.
Qed.

(* FILL IN HERE

    [] *)

(** **** Exercise: 4 stars, advanced, optional (NoDup)

    Recall the definition of the [In] property from the [Logic]
    chapter, which asserts that a value [x] appears at least once in a
    list [l]: *)

(* Fixpoint In (A : Type) (x : A) (l : list A) : Prop :=
   match l with
   | [] => False
   | x' :: l' => x' = x \/ In A x l'
   end *)

(** Your first task is to use [In] to define a proposition [disjoint X
    l1 l2], which should be provable exactly when [l1] and [l2] are
    lists (with elements of type X) that have no elements in
    common. *)

(* FILL IN HERE *)

Definition disjoint {X : Type} (l1 : list X) (l2 : list X) : Prop :=
  forall (x : X), ~ (In x l1 /\ In x l2).

(** Next, use [In] to define an inductive proposition [NoDup X
    l], which should be provable exactly when [l] is a list (with
    elements of type [X]) where every member is different from every
    other.  For example, [NoDup nat [1;2;3;4]] and [NoDup
    bool []] should be provable, while [NoDup nat [1;2;1]] and
    [NoDup bool [true;true]] should not be.  *)

(* FILL IN HERE *)

Inductive NoDup {X : Type} : list X -> Prop :=
| NoDupEmpty : NoDup []
| NoDupNonempty (x : X) (l : list X) (H1 : NoDup l) (H2 : ~ (In x l)) : NoDup (x::l)
.

(** Finally, state and prove one or more interesting theorems relating
    [disjoint], [NoDup] and [++] (list append).  *)

Theorem app_disjoint_no_dups { X : Type } :
  forall (l l' : list X), NoDup l /\ NoDup l' /\ disjoint l l' <-> NoDup (l ++ l').
Proof.
  induction l as [| x l'' IH ].
  - simpl. intros l. split.
    + intros [ _ [ H _ ]]. apply H.
    + intros H.
      split.
        { apply NoDupEmpty. }
      split.
        { apply H. }
        { unfold disjoint. intros x [ contra _ ]. inversion contra. }
  - intros l. split.
    + intros [ H1 [ H2 H3 ]].
      (* Unpack hypotheses *)
      inversion H1 as [| y l''2 Hl'' Hx H1_head ].
      unfold disjoint in H3.
      (* Now prove the goal *)
      rewrite cons_app_distr.
      apply NoDupNonempty.
      * rewrite <- (IH l).
        split.
          { apply Hl''. }
        split.
          { apply H2. }
          { unfold disjoint. intros x' [ H4 H5 ].
            apply (H3 x'). split.
              ** right. apply H4.
              ** apply H5. }
      * intros contra.
        rewrite (In_app_iff X l'' l x) in contra.
        destruct contra as [ contra | contra ].
         { apply Hx. apply contra. }
         { apply (H3 x). split.
            ** left. reflexivity.
            ** apply contra. }
    + rewrite cons_app_distr. intros H.
      inversion H as [| y l''2 Hl'' Hx Hhead ].
      rewrite <- (IH l) in Hl''.
      destruct Hl'' as [ H1 [ H2 H3 ]].
      split.
      * apply NoDupNonempty.
          { apply H1. }
          { intros contra. apply Hx. apply In_app_iff. left. apply contra. }
      * split.
        ** apply H2.
        ** unfold disjoint. intros x' [ H4 H5 ].
           destruct H4 as [ H4 | H4 ].
           *** apply Hx. apply In_app_iff. right. rewrite H4. apply H5.
           *** apply (H3 x').
               split.
                 { apply H4. }
                 { apply H5. } 
Qed.

(* FILL IN HERE *)

(* Do not modify the following line: *)
Definition manual_grade_for_NoDup_disjoint_etc : option (nat*string) := None.
(** [] *)

(** **** Exercise: 4 stars, advanced, optional (pigeonhole_principle)

    The _pigeonhole principle_ states a basic fact about counting: if
    we distribute more than [n] items into [n] pigeonholes, some
    pigeonhole must contain at least two items.  As often happens, this
    apparently trivial fact about numbers requires non-trivial
    machinery to prove, but we now have enough... *)

(** First prove an easy and useful lemma. *)

Lemma in_split : forall (X:Type) (x:X) (l:list X),
  In x l ->
  exists l1 l2, l = l1 ++ x :: l2.
Proof.
  intros X x.
  induction l as [| y l' IH ].
  - intros H.
    exfalso.
    inversion H.
  - intros [ H | H ].
    + exists [], l'. simpl. rewrite H. reflexivity.
    + destruct (IH H) as [ l1 [ l2 H' ]].
      exists (y::l1), l2.
      rewrite cons_app_distr.
      f_equal. apply H'.
Qed.    
     
(** Now define a property [repeats] such that [repeats X l] asserts
    that [l] contains at least one repeated element (of type [X]).  *)

Inductive repeats {X:Type} : list X -> Prop :=
| RepeatsBase (x : X) (l : list X) (H : In x l)    : repeats (x::l)
| RepeatsStep (x : X) (l : list X) (H : repeats l) : repeats (x::l)
.

(* Do not modify the following line: *)
Definition manual_grade_for_check_repeats : option (nat*string) := None.

(** Now, here's a way to formalize the pigeonhole principle.  Suppose
    list [l2] represents a list of pigeonhole labels, and list [l1]
    represents the labels assigned to a list of items.  If there are
    more items than labels, at least two items must have the same
    label -- i.e., list [l1] must contain repeats.

    This proof is much easier if you use the [excluded_middle]
    hypothesis to show that [In] is decidable, i.e., [forall x l, (In x
    l) \/ ~ (In x l)].  However, it is also possible to make the proof
    go through _without_ assuming that [In] is decidable; if you
    manage to do this, you will not need the [excluded_middle]
    hypothesis. *)

Theorem pigeonhole_principle: excluded_middle ->
  forall (X:Type) (l1 l2:list X),
  (forall x, In x l1 -> In x l2) ->
  length l2 < length l1 ->
  repeats l1.
Proof.
  intros EM X l1. induction l1 as [|x l1' IH].
  - simpl. intros l2 _ H. inversion H.
  - destruct l1' eqn:E.
    + simpl. intros l2 H1 H2.
      destruct l2.
      * assert (contra : In x []).
          { apply H1. left. reflexivity. }
        inversion contra.
      * simpl in H2. unfold lt in H2.
        inversion H2 as [| n H3 H4 ]. inversion H3.
    + rewrite <- E in *.
      intros l2 HIn Hlength.
      
      destruct (EM (In x l1')) as [ H | H ].
      * apply RepeatsBase. apply H.
      * (* Use the inductive hypothesis *)
        apply RepeatsStep.
        apply IH with l2.
        -- intros x' Hx'. apply HIn. right. apply Hx'.
        --   
Abort.

Definition in_decidable (X : Type) : Prop :=
  forall (x : X) (l : list X), In x l \/ ~ In x l.

Lemma pigeonhole_principle_core:
  forall (X:Type), in_decidable X ->  
  forall (l1 l2:list X),  
  (forall x, In x l1 -> In x l2) ->
  length l2 < length l1 ->
  repeats l1.
Proof.
  intros X DecidableIn l1. induction l1 as [|x l1' IH].
  - simpl. intros l2 _ H. inversion H.
  - intros l2 H1 H2.
    destruct (DecidableIn x l1') as [ H | H ].
    + apply RepeatsBase. apply H.
    + inversion H2 as [ H3 | m H3 H4 ].
      * (* By H1, we have In x l2 *)
        assert (In x l2) as Hxl2.
          { apply H1. left. reflexivity. }
        (* So, by in_split, we have l2 = l2' ++ x :: l2'', for some l2', l2'' *)
        destruct (in_split X x l2 Hxl2) as [ l2' [ l2'' Hl2 ]].
        (* We have that forall y, In y l1' -> In y (l2' ++ l2'') *)
        (* Here, the assumption ~ In x l1' is crucial, since l2' and l2'' are
           not guaranteed to contain x; i.e. we removed potentially the only
           occurrence of x from l2. *)
        (* We also have the length (l2' ++ l2'') < length l2 = length l1' *)
        (* So we can apply the IH to obtain repeats l1' *)
        (* And then the result follows *)
        apply RepeatsStep.
        apply IH with (l2' ++ l2'').
        -- (* forall x, In x l1' -> In x (l2' ++ l2'') *)
           intros x' Hx'.
           apply In_app_iff.
           rewrite Hl2 in H1.
           assert (In x' (l2' ++ x :: l2'')) as Hx'2.
             { apply H1. right. apply Hx'. }
           rewrite (In_app_iff X l2' (x::l2'') x') in Hx'2.
           destruct Hx'2 as [ H4 | H4 ].
           ++  left. apply H4.
           ++  right. destruct H4 as [ H5 | H5 ].
           +++ exfalso. apply H. rewrite H5. apply Hx'.
           +++ apply H5.
        -- (* length (l2' ++ l2'') < length l2 = length l1' *)
           unfold lt.
           transitivity (length l2).
           ++ rewrite Hl2.
              rewrite app_length. rewrite app_length. simpl.
              rewrite plus_n_Sm.
              apply plus_le_compat_l.
              apply n_le_m__Sn_le_Sm.
              apply le_n.
           ++ rewrite H3. apply le_n.
      * apply RepeatsStep.
        apply IH with l2.
        -- intros x' Hx'. apply H1. right. apply Hx'.
        -- apply H3.
Qed.

Theorem pigeonhole_principle: excluded_middle ->
  forall (X:Type) (l1 l2:list X),
  (forall x, In x l1 -> In x l2) ->
  length l2 < length l1 ->
  repeats l1.
Proof.
  intros EM X.
  assert (DecidableIn : in_decidable X).
    { intros x l. apply (EM (In x l)). }
  apply (pigeonhole_principle_core X DecidableIn).
Qed.

(* Now for the constructive version. *)

(* First, a couple of useful lemmas we'll need for what's to come. *)

Lemma succ_not_looping : forall n, ~ S n <= n.
Proof.
  induction n as [| n' IH ].
  - intros contra. inversion contra.
  - intros contra. apply IH. apply Sn_le_Sm__n_le_m. apply contra.
Qed.

Lemma equal_list_lengths { X : Type } : forall l1 l2 l3 l4 : list X,
  l1 ++ l2 = l3 ++ l4 -> length l2 = length l4 -> l2 = l4.
Proof.
  induction l1 as [| x l' IH ].
  - simpl.
    intros l2 l3. generalize dependent l2.
    induction l3 as [| y l3' IH' ].
    + simpl. intros l2 l4 H _. apply H.
    + intros l2 l4 H1 H2.
      exfalso.
      rewrite H1 in H2. simpl in H2.
      rewrite app_length in H2.
      rewrite add_comm in H2.
      rewrite plus_n_Sm in H2.
Abort.
Lemma equal_list_lengths { X : Type } : forall l1 l2 l3 l4 : list X,
  l1 ++ l2 = l3 ++ l4 -> length l2 = length l4 -> l1 = l3 /\ l2 = l4.
Proof.
  intros l1 l2.
  generalize dependent l1.
  induction l2 as [| x l2' IH ].
  - simpl. intros l1 l3 l4 Hlists contra.
    induction l4 as [| x l4' IH' ].
    + split.
        { rewrite app_nil_r in Hlists. rewrite app_nil_r in Hlists. apply Hlists. }
        { reflexivity. }
    + exfalso. simpl in contra. discriminate contra.
  - intros l1 l3 l4 Hlists Hlength.
    destruct l4 as [| y l4' ] eqn:Hl4 .
    + simpl in Hlength. discriminate Hlength.
    + assert (H : (l1 ++ [x]) = (l3 ++ [y]) /\ l2' = l4').
        {
          apply IH.
          * rewrite <- app_assoc. rewrite <- app_assoc. simpl. apply Hlists.
          * simpl in Hlength. injection Hlength as Hlength. apply Hlength. 
        }
      destruct H as [ H1 H2 ].
      (* x = y /\ l1 = l3 *)
      rewrite <- rev_involutive in H1. rewrite rev_app_distr in H1.
        replace (rev [y]) with [y] in H1 by reflexivity.
      replace (l1 ++ [x]) with (rev (rev (l1 ++ [x]))) in H1
        by apply rev_involutive.
      rewrite rev_app_distr in H1.
        replace (rev [x]) with [x] in H1 by reflexivity.
      apply (f_equal (list X) (list X) rev) in H1.
      rewrite rev_involutive in H1. rewrite rev_involutive in H1.
      simpl in H1. injection H1 as Hxy Hlists'.
      apply (f_equal (list X) (list X) rev) in Hlists'.
      rewrite rev_involutive in Hlists'. rewrite rev_involutive in Hlists'.
      (* Now prove the main goals *)
      split.
      * apply Hlists'.
      * rewrite Hxy. rewrite H2. reflexivity.
Qed.

(* An aside: now it's clear that the app_injective_l lemma above is a
   corollary of the equal_list_lengths lemma above. The interesting this is that
   I realised that the full generality of app_injective_l wasn't needed for the
   rev_pal result, and only reasoning involving rev and injectivity of cons was
   needed. It seemed like the general app_injective_l result needed more
   complex reasoning, involving lists not being circular. However, the proof of
   equal_list_lengths crucially uses rev and injectivity of cons for the
   inductive case! *)

Lemma app_injective_l' { X : Type } :
  forall (l1 l2 l3 : list X), l1 ++ l3 = l2 ++ l3 -> l1 = l2.
Proof.
  intros l1 l2 l3 H.
  apply proj1 with (l3 = l3).
  apply equal_list_lengths.
  - apply H.
  - reflexivity.
Qed.

(* We need some machinery for identifying where in a list a
   particular element occurs. *)

(* Question: why have I decided to count indices from the RIGHT of the list?? *)

Definition At { X : Type } (x : X) (n : nat) (l : list X) : Prop :=
  exists (l1 l2 : list X),
    l = l1 ++ x :: l2 /\ length l2 = n.

Lemma AtIn { X : Type } : 
  forall (x : X) (l : list X),
    In x l <-> (exists (n : nat), n < length l /\ At x n l).
Proof.
  intros x l.
  induction l as [| y l' IH ].
  - split.
    + intros contra. inversion contra.
    + simpl. intros [n [contra _]].
      assert (H : forall n, ~ (n < 0)).
        { unfold lt. intros n' contra'. inversion contra'. }
      apply (H n). apply contra.
  - split.
    + intros H.
      inversion H as [ H' | H' ].
      * exists (length l'). split.
        ** unfold lt. simpl. apply le_n.
        ** exists [], l'. split.
             { rewrite H'. reflexivity. }
             { reflexivity. }
      * apply IH in H'. destruct H' as [n [H1 H2]].
        exists n. split.
        ** unfold lt.
           transitivity (length l').
             { apply H1. }
             { simpl. apply le_S. reflexivity. }
        ** destruct H2 as [l1 [l2 [H3 H4]]].
           exists (y::l1), l2.
           split.
             { rewrite H3. reflexivity. }
             { apply H4. }
    + intros [n [H1 H2]].
      inversion H1 as [|].
      * destruct H2 as [l1 [l2 [H3 H4]]].
        assert (H5 : length l' = length l2).
          { transitivity n. { symmetry. apply H. } { symmetry. apply H4. } }
        replace (l1 ++ x :: l2) with ((l1 ++ [x]) ++ l2) in H3
          by (rewrite <- app_assoc; reflexivity).
        destruct (equal_list_lengths  [y] l' (l1 ++ [x]) l2 H3 H5) as [ H6 H7 ].
        replace ([y]) with ([] ++ [y]) in H6 by reflexivity.
        assert (H8 : length [y] = length [x]). { reflexivity. }
        destruct (equal_list_lengths [] [y] l1 [x] H6 H8) as [ _ H9 ].
        injection H9 as H9.
        left. apply H9.
      * right. apply IH.
        exists n. split.
        ** apply H.
        ** destruct H2 as [l1 [l2 [H3 H4]]].
           destruct l1 as [| z l'' ].
           *** simpl in H3.
               injection H3 as _ H3.
               exfalso.
               apply succ_not_looping with n.
               rewrite H3 in H. rewrite H4 in H. apply H.
           *** injection H3 as _ H3.
               exists l'', l2. split.
                 { apply H3. }
                 { apply H4. }
Qed.

Lemma AtExists { X : Type } :
  forall n (l : list X), n < length l -> exists x, At x n l.
Proof.
  intros n l.
  generalize dependent n.
  induction l as [| x l' IH ].
  - unfold lt. simpl. intros n contra. inversion contra.
  - intros n Hn.
    inversion Hn as [| m Hm Heq ].
    + exists x. unfold At. exists [], l'.
      split.
        { reflexivity. }
        { reflexivity. }
    + destruct (IH n Hm) as [ y [ l1 [ l2 [ H1 H2 ]]]]. 
      exists y. unfold At. exists (x::l1), l2.
      split.
      * simpl. rewrite H1. reflexivity.
      * apply H2.
Qed.

Lemma AtEmpty { X : Type } : ~ exists (x : X) n, At x n [].
Proof.
  intros [ x [ n [ l1 [ l2 [ contra _ ]]]]].
  destruct l1.
  - discriminate contra.
  - discriminate contra.
Qed.

Lemma IndexBounded { X : Type } :
  forall (x : X) (n : nat) (l : list X), At x n l -> n < length l.
Proof.
  intros x n l [ l1 [ l2 [ H1 H2 ]]].
  rewrite H1.
  rewrite app_length.
  unfold lt.
  transitivity ((length l1) + S n).
  - rewrite add_comm. apply le_plus_l.
  - apply plus_le_compat_l. simpl.
    apply n_le_m__Sn_le_Sm. rewrite H2. apply le_n. 
Qed.

(* The following is the key lemma: it says that we can lift an instance of the
   pigeonhole principle for an arbitrary type X to the setting of lists of
   natural numbers by converting the elements of the list l1 to indices
   corresponding to where those elements appear in l2. Membership for lists of
   natural numbers is decidable, so we can show the pigenhole principle holds
   there. We then pull the property back into the realm of the type X, which we
   can do because of the properties of the lifting we have constructed. *)

Lemma conversion { X : Type } :
  forall (l1 l2 : list X),
    (forall x, In x l1 -> In x l2) ->
      exists (l1' l2' : list nat),
        (length l1' = length l1) /\ (length l2' = length l2)
          /\
        (forall n, In n l1' -> In n l2')
          /\
        (forall n, n < length l2' -> At n n l2')
          /\
        (forall (x : X) (n idx : nat),
          At x n l1 /\ At idx n l1' -> At x idx l2).
Proof.
  induction l1 as [| x l1'' IH ].
  - induction l2 as [| y l2'' IH' ].
    + intros HIn.
      exists [], [].
      split.
        { reflexivity. }
      split.
        { reflexivity. }
      split.
        {  intros n contra. inversion contra. }
      split.
        { intros n contra. unfold lt in contra. inversion contra. }
        { intros x n idx [ H _ ]. inversion H as [ l contra ].
          destruct contra as [ l2 [ contra _ ]]. 
          destruct l.
            - discriminate contra.
            - discriminate contra.
        }
    + intros HIn.
      assert (HIn' : forall x, In x [] -> In x l2'').
        { intros x contra. inversion contra. }
      destruct (IH' HIn') as [l1' [l2' [H1 [H2 [H3 [H4 H5]]]]]].
      exists [], ((length l2')::l2').
      split.
        { reflexivity. }
      split.
        { simpl. rewrite H2. reflexivity. }
      split.
        { intros n contra. inversion contra. }
      split.
        { 
          intros n Hn. unfold lt in Hn.
          inversion Hn as [ Hn' | m Hn' Hm ].
          - exists [], l2'. split.
            + reflexivity.
            + reflexivity.
          - destruct (H4 n Hn') as [l [l' [H6 H7]]].
            exists ((length l2')::l), l'. split.
            + simpl. rewrite <- H6. reflexivity.
            + apply H7. 
        }
        { intros x n idx H6.
          assert (H7 : l1' = []).
            { destruct l1'.
              - reflexivity.
              - simpl in H1. discriminate H1.
            }
          rewrite H7 in H5.
          destruct (H5 x n idx H6) as [l [l' [H8 H9]]].
          exists (y::l), l'. split.
          - simpl. rewrite H8. reflexivity.
          - apply H9. 
        }
  - intros l2 HIn.
    assert (HIn' : forall x, In x l1'' -> In x l2).
      { intros x' H. apply HIn. right. apply H. }
    destruct (IH l2 HIn') as [l1' [l2' [H1 [H2 [H3 [H4 H5]]]]]].
    assert (Hx : In x l2).
      { apply HIn. left. reflexivity. }
    rewrite AtIn in Hx.
    destruct Hx as [ idx [ Hidx HAt ] ].
    destruct HAt as [l [l' [ H6 H7 ]]].
    exists (idx::l1'), l2'.
    split.
      { simpl. rewrite H1. reflexivity. }
    split.
      { apply H2. }
    split.
      { intros n [ Hn | Hn ].
        - (* n = idx *)
          apply AtIn.
          exists idx. split.
          + rewrite H2. apply Hidx.
          + rewrite <- Hn. apply H4. rewrite H2. apply Hidx.
        - (* In n l1' *)
          apply H3. apply Hn.
      }
    split.
      { apply H4. }
      { 
        intros x' n idx' [Hx' Hidx'].
        (* At x' n (x::l1'') /\ At idx' n (idx::l1')
           So either:
           - x' = x /\ idx' = idx /\ n = length l1'' = length l1'
               in which case rewrite equalities, and conclude with H6 and H7
           - At x' n l1'' /\ At idx' n l1'
               in which case conclude with H5
         *)
        destruct Hx' as [l3 [l4 [H8 H9]]].
        destruct Hidx' as [l5 [l6 [H10 H11]]].
        destruct l3 as [| y l3' ].
        - destruct l5 as [| y' l5' ].
          + (* x' = x /\ idx' = idx /\ n = length l1'' = length l1' *)
            injection H8 as Hx _. rewrite <- Hx.
            injection H10 as Hidx' _. rewrite <- Hidx'.
            exists l, l'. split.
            * apply H6.
            * apply H7.
          + injection H8 as _ Hl1''.
            injection H10 as _ Hl1'.
            exfalso.
            (* length l1' = length l1'' = length l4 = n = length l6
                 < length (l5' ++ idx' :: l6) = length l1' *)
            apply succ_not_looping with (length l1').
            transitivity (length (l5' ++ idx' :: l6)).
            * transitivity (S (length l6)).
              ** rewrite H1. rewrite Hl1''. rewrite H9. rewrite H11. apply le_n.
              ** rewrite app_length. rewrite add_comm. apply le_plus_trans.
                 simpl. apply le_n.
            * rewrite Hl1'. apply le_n.
        - injection H8 as _ Hl1''.
          destruct l5 as [| y' l5' ].
          + injection H10 as _ Hl1'.
            exfalso.
            (* length l1'' = length l1' = length l6 = n = length l4
                 < length (l3' ++ x' :: l4) = length l1'' *)
            apply succ_not_looping with (length l1'').
            transitivity (length (l3' ++ x' :: l4)).
            * transitivity (S (length l4)).
              ** rewrite <- H1. rewrite Hl1'. rewrite H11. rewrite H9. apply le_n.
              ** rewrite app_length. rewrite add_comm. apply le_plus_trans.
                 simpl. apply le_n.
            * rewrite Hl1''. apply le_n.
          + (* At x' n l1'' /\ At idx' n l1' *)
            apply H5 with n. split.
            * exists l3', l4. split.
                { apply Hl1''. }
                { apply H9. }
            * injection H10 as _ Hl1'.
              exists l5', l6. split.
                { apply Hl1'. }
                { apply H11. }
      }
Qed.

(* We now show a lemma that if equaity of elements of a type X is decidable,
   then so is membership in lists of elements of that type. *)

Lemma EqualityListMembershipDecidable { X : Type } :
  (exists (eq : X -> X -> bool), forall (x y : X),  (x = y) <-> (eq x y) = true)
    -> (forall (x : X) (l : list X), In x l \/ ~ (In x l)).
Proof.
  intros [ eq Heq ] x l.
  induction l as [| y l' IH ].
  - right. intros contra. inversion contra.
  - destruct IH as [ HIn | HNotIn ].
    + left. right. apply HIn.
    + destruct (eq x y) eqn:HEq'.
      * left. left. symmetry. rewrite Heq. apply HEq'.
      * right. intros [ contra | contra ].
        { symmetry in contra. rewrite Heq in contra. rewrite HEq' in contra.
          discriminate contra. }
        { apply HNotIn. apply contra. }
Qed.

(* The relevant corollary of this is that membership in lists of natural numbers
   is decidable. *)

Lemma InNatListDecidable : in_decidable nat.
Proof.
  unfold in_decidable.
  apply EqualityListMembershipDecidable.
  exists eqb.
  intros x y.
  assert (H : reflect (x = y) (x =? y)).
    { apply eqbP. }
  inversion H.
  - rewrite H1. split. reflexivity. reflexivity.
  - split.
    + intros Hxy. exfalso. apply H1. apply Hxy.
    + intros contra. discriminate contra.
Qed.

(* Some final lemmas needed for the pull back. *)

Lemma pad_repeat { X : Type } :
  forall (l1 l2 : list X), repeats l1 -> repeats (l2 ++ l1).
Proof.
  intros l1 l2.
  generalize dependent l1.
  induction l2 as [| x l' IH ].
  - intros l1 H. apply H.
  - intros l1 H. simpl. apply RepeatsStep. apply IH. apply H.
Qed.

Lemma repeated_elements { X : Type } :
  forall (l : list X),
    repeats l <-> 
      exists x idx1 idx2, idx1 <> idx2 /\ At x idx1 l /\ At x idx2 l.
Proof.
  induction l as [| x l' IH ].
  - split.
    + intros contra. inversion contra.
    + intros H.
      exfalso.
      apply (@AtEmpty X).
      destruct H as [ x [ n [ _ [ _ [ H _ ]]]]].
      exists x, n. apply H.
  - split.
    + intros H.
      inversion H as [ y l'' H' EqHead | y l'' H' EqHead ].
      * apply AtIn in H'. 
        destruct H' as [ n [ H1 H2 ]].
        exists x, (length l'), n.
        split.
        ** intros contra.
           unfold lt in H1. rewrite <- contra in H1.
           apply succ_not_looping with (length l').
           apply H1.
        ** split.
        *** exists [], l'.
            split.
              { reflexivity. }
              { reflexivity. }
        *** destruct H2 as [ l1 [ l2 [ H3 H4 ]]].
            exists (x::l1), l2.
            split.
              { rewrite H3. reflexivity. }
              { apply H4. }
      * apply IH in H'.
        destruct H' as [ x' [ idx1 [ idx2 [ H1 [ H2 H3 ]]]]].
        exists x', idx1, idx2.
        split.
        ** apply H1.
        ** split.
        *** destruct H2 as [ l1 [ l2 [ H4 H5 ]]].
            exists (x::l1), l2.
            split.
              { rewrite H4. reflexivity. }
              { apply H5. }
        *** destruct H3 as [ l1 [ l2 [ H4 H5 ]]].
            exists (x::l1), l2.
            split.
              { rewrite H4. reflexivity. }
              { apply H5. }
    + intros [ x' [ idx1 [ idx2 [ H1 [ H2 H3 ]]]]].
      (* idx1 or idx2 might be (length l') - i.e. correspond to x *)
      destruct H2 as [l1 [l2 [H4 H5]]].
      destruct H3 as [l3 [l4 [H6 H7]]].
      destruct l1 as [| y l1 ].
      * destruct l3 as [| y' l3 ].
        ** exfalso. apply H1.
           rewrite H4 in H6. simpl in H6.
           injection H6 as H8.
           rewrite H8 in H5.
           rewrite H5 in H7.
           apply H7.
        ** apply RepeatsBase. apply AtIn.
           exists idx2.
           injection H6 as _ H8.
           split.
           *** rewrite H8. rewrite app_length.
               unfold lt. transitivity (length (x'::l4)).
                 { simpl. rewrite H7. apply le_n. }
                 { rewrite add_comm. apply le_plus_l. }
           *** exists l3, l4.
               split.
                 { injection H4 as H9 _. rewrite H9. apply H8. }
                 { apply H7. }
      * destruct l3 as [| y' l3 ].
        ** apply RepeatsBase. apply AtIn.
           exists idx1.
           injection H4 as _ H8.
           split.
           *** rewrite H8. rewrite app_length.
               unfold lt. transitivity (length (x'::l2)).
                 { simpl. rewrite H5. apply le_n. }
                 { rewrite add_comm. apply le_plus_l. }
           *** exists l1, l2.
               split.
                 { injection H6 as H9 _. rewrite H9. apply H8. }
                 { apply H5. }
        ** apply RepeatsStep. apply IH.
           exists x', idx1, idx2.
           split.
             { apply H1. }
           split.
            *** exists l1, l2. split.
                  { injection H4 as _ H4. apply H4. }
                  { apply H5. }
            *** exists l3, l4. split.
                  { injection H6 as _ H6. apply H6. }
                  { apply H7. }
Qed.

(* We can now show the pigeonhold principle holds constructively. *)

Theorem pigeonhole_principle_constructive:
  forall (X:Type) (l1 l2:list X),
  (forall x, In x l1 -> In x l2) ->
  length l2 < length l1 ->
  repeats l1.
Proof.
  intros X l1 l2 H H'.
  (* Convert the problem to the nat context *)
  destruct (conversion l1 l2 H) as [ l1' [ l2' [ H1 [ H2 [ H3 [ H4 H5 ]]]]]].
  (* apply the core lemma *)
  assert (Hl1 : repeats l1').
    { apply pigeonhole_principle_core with l2'.
      - apply InNatListDecidable.
      - apply H3.
      - rewrite H1. rewrite H2. apply H'.  
    }
  (* pull back. *)
  rewrite repeated_elements in Hl1.
  destruct Hl1 as [ x_idx [ idx1 [ idx2 [ Hidxs [ Hidx1 Hidx2 ]]]]].
  assert (Hx1 : exists x, At x idx1 l1).
    { apply AtExists. rewrite <- H1. apply IndexBounded with x_idx. apply Hidx1. }
  destruct Hx1 as [ x1 Hx1 ].
  assert (Hx1' : At x1 x_idx l2).
    { apply H5 with idx1. split. apply Hx1. apply Hidx1. }
  assert (Hx2 : exists x, At x idx2 l1).
    { apply AtExists. rewrite <- H1. apply IndexBounded with x_idx. apply Hidx2. }
  destruct Hx2 as [ x2 Hx2 ].
  assert (Hx2' : At x2 x_idx l2).
    { apply H5 with idx2. split. apply Hx2. apply Hidx2. }
  assert (H6 : x1 = x2).
    { 
      destruct Hx1' as [ l3 [ l3' [ H6 H7 ]]].
      destruct Hx2' as [ l4 [ l4' [ H8 H9 ]]].
      assert (H10 : x1::l3' = x2::l4').
        { apply equal_list_lengths with l3 l4. rewrite <- H6.
          - apply H8.
          - simpl. f_equal. rewrite H7. rewrite H9. reflexivity.
        }
      injection H10 as H11 _. apply H11.
    }
  rewrite (repeated_elements l1).
  exists x1, idx1, idx2.
  split.
  - apply Hidxs.
  - split.
    + apply Hx1.
    + rewrite H6. apply Hx2.
Qed.
(** [] *)

(* ================================================================= *)
(** ** Extended Exercise: A Verified Regular-Expression Matcher *)

(** We have now defined a match relation over regular expressions and
    polymorphic lists. We can use such a definition to manually prove that
    a given regex matches a given string, but it does not give us a
    program that we can run to determine a match automatically.

    It would be reasonable to hope that we can translate the definitions
    of the inductive rules for constructing evidence of the match relation
    into cases of a recursive function that reflects the relation by recursing
    on a given regex. However, it does not seem straightforward to define
    such a function in which the given regex is a recursion variable
    recognized by Coq. As a result, Coq will not accept that the function
    always terminates.

    Heavily-optimized regex matchers match a regex by translating a given
    regex into a state machine and determining if the state machine
    accepts a given string. However, regex matching can also be
    implemented using an algorithm that operates purely on strings and
    regexes without defining and maintaining additional datatypes, such as
    state machines. We'll implement such an algorithm, and verify that
    its value reflects the match relation. *)

(** We will implement a regex matcher that matches strings represented
    as lists of ASCII characters: *)
Require Import Coq.Strings.Ascii.

Definition string := list ascii.

(** The Coq standard library contains a distinct inductive definition
    of strings of ASCII characters. However, we will use the above
    definition of strings as lists as ASCII characters in order to apply
    the existing definition of the match relation.

    We could also define a regex matcher over polymorphic lists, not lists
    of ASCII characters specifically. The matching algorithm that we will
    implement needs to be able to test equality of elements in a given
    list, and thus needs to be given an equality-testing
    function. Generalizing the definitions, theorems, and proofs that we
    define for such a setting is a bit tedious, but workable. *)

(** The proof of correctness of the regex matcher will combine
    properties of the regex-matching function with properties of the
    [match] relation that do not depend on the matching function. We'll go
    ahead and prove the latter class of properties now. Most of them have
    straightforward proofs, which have been given to you, although there
    are a few key lemmas that are left for you to prove. *)

(** Each provable [Prop] is equivalent to [True]. *)
Lemma provable_equiv_true : forall (P : Prop), P -> (P <-> True).
Proof.
  intros.
  split.
  - intros. constructor.
  - intros _. apply H.
Qed.

(** Each [Prop] whose negation is provable is equivalent to [False]. *)
Lemma not_equiv_false : forall (P : Prop), ~P -> (P <-> False).
Proof.
  intros.
  split.
  - apply H.
  - intros. destruct H0.
Qed.

(** [EmptySet] matches no string. *)
Lemma null_matches_none : forall (s : string), (s =~ EmptySet) <-> False.
Proof.
  intros.
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [EmptyStr] only matches the empty string. *)
Lemma empty_matches_eps : forall (s : string), s =~ EmptyStr <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MEmpty.
Qed.

(** [EmptyStr] matches no non-empty string. *)
Lemma empty_nomatch_ne : forall (a : ascii) s, (a :: s =~ EmptyStr) <-> False.
Proof.
  intros.
  apply not_equiv_false.
  unfold not. intros. inversion H.
Qed.

(** [Char a] matches no string that starts with a non-[a] character. *)
Lemma char_nomatch_char :
  forall (a b : ascii) s, b <> a -> (b :: s =~ Char a <-> False).
Proof.
  intros.
  apply not_equiv_false.
  unfold not.
  intros.
  apply H.
  inversion H0.
  reflexivity.
Qed.

(** If [Char a] matches a non-empty string, then the string's tail is empty. *)
Lemma char_eps_suffix : forall (a : ascii) s, a :: s =~ Char a <-> s = [ ].
Proof.
  split.
  - intros. inversion H. reflexivity.
  - intros. rewrite H. apply MChar.
Qed.

(** [App re0 re1] matches string [s] iff [s = s0 ++ s1], where [s0]
    matches [re0] and [s1] matches [re1]. *)
Lemma app_exists : forall (s : string) re0 re1,
  s =~ App re0 re1 <->
  exists s0 s1, s = s0 ++ s1 /\ s0 =~ re0 /\ s1 =~ re1.
Proof.
  intros.
  split.
  - intros. inversion H. exists s1, s2. split.
    * reflexivity.
    * split. apply H3. apply H4.
  - intros [ s0 [ s1 [ Happ [ Hmat0 Hmat1 ] ] ] ].
    rewrite Happ. apply (MApp s0 _ s1 _ Hmat0 Hmat1).
Qed.

(** **** Exercise: 3 stars, standard, optional (app_ne)

    [App re0 re1] matches [a::s] iff [re0] matches the empty string
    and [a::s] matches [re1] or [s=s0++s1], where [a::s0] matches [re0]
    and [s1] matches [re1].

    Even though this is a property of purely the match relation, it is a
    critical observation behind the design of our regex matcher. So (1)
    take time to understand it, (2) prove it, and (3) look for how you'll
    use it later. *)
Lemma app_ne : forall (a : ascii) s re0 re1,
  a :: s =~ (App re0 re1) <->
  ([ ] =~ re0 /\ a :: s =~ re1) \/
  exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re0 /\ s1 =~ re1.
Proof.
  intros a s re0 re1.
  split.
  { (* The -> direction *)
    intros H. inversion H.
    destruct s1 as [| b s1' ].
    - left. split.
      + apply H3.
      + apply H4.
    - right.
      injection H1 as Hab Hs.
      exists s1', s2.
      split.
        { symmetry. apply Hs. }
      split.
        { rewrite <- Hab. apply H3. }
        { apply H4. }
  }
  { (* The <- direction *)
    intros [ [ H1 H2 ] | [s0 [s1 [ H1 [ H2 H3 ]]]] ].
    - replace (a::s) with ([] ++ a::s) by reflexivity.
      constructor. apply H1. apply H2.
    - rewrite H1.
      replace (a :: s0 ++ s1) with ((a :: s0) ++ s1) by reflexivity.
      constructor. apply H2. apply H3.
  }
Qed.
(** [] *)

(** [s] matches [Union re0 re1] iff [s] matches [re0] or [s] matches [re1]. *)
Lemma union_disj : forall (s : string) re0 re1,
  s =~ Union re0 re1 <-> s =~ re0 \/ s =~ re1.
Proof.
  intros. split.
  - intros. inversion H.
    + left. apply H2.
    + right. apply H1.
  - intros [ H | H ].
    + apply MUnionL. apply H.
    + apply MUnionR. apply H.
Qed.

(** **** Exercise: 3 stars, standard, optional (star_ne)

    [a::s] matches [Star re] iff [s = s0 ++ s1], where [a::s0] matches
    [re] and [s1] matches [Star re]. Like [app_ne], this observation is
    critical, so understand it, prove it, and keep it in mind.

    Hint: you'll need to perform induction. There are quite a few
    reasonable candidates for [Prop]'s to prove by induction. The only one
    that will work is splitting the [iff] into two implications and
    proving one by induction on the evidence for [a :: s =~ Star re]. The
    other implication can be proved without induction.

    In order to prove the right property by induction, you'll need to
    rephrase [a :: s =~ Star re] to be a [Prop] over general variables,
    using the [remember] tactic.  *)

Lemma star_ne : forall (a : ascii) s re,
  a :: s =~ Star re <->
  exists s0 s1, s = s0 ++ s1 /\ a :: s0 =~ re /\ s1 =~ Star re.
Proof.
  intros a s re.
  split.
  { (* Left-to-right*)
    intros H.
    remember (a :: s) as s' eqn:Hs'.
    remember (Star re) as re' eqn: Hre'.
    induction H as [|x'|s1 re1 s2' re2 Hmatch1 IH1 Hmatch2 IH2
                    |s1 re1 re2 Hmatch IH|re1 s2' re2 Hmatch IH
                    |re''|s1 s2' re'' Hmatch1 IH1 Hmatch2 IH2].
    - discriminate Hre'.
    - discriminate Hre'.
    - discriminate Hre'.
    - discriminate Hre'.
    - discriminate Hre'.
    - discriminate Hs'.
    - destruct s1 as [| b s1' ].
      + destruct s2' as [| b s2' ].
        * discriminate Hs'.
        * apply IH2.
            { apply Hs'. }
            { apply Hre'. }
      + injection Hs' as Ha Hs.
        exists s1', s2'.
        split.
          { symmetry. apply Hs. }
        split.
          { rewrite <- Ha. injection Hre' as Hre. rewrite <- Hre. apply Hmatch1. }
          { apply Hmatch2. }
  }
  { (* Right-to-left *)
    intros [s0 [s1 [H1 [H2 H3]]]].
    rewrite H1.
    replace (a :: s0 ++ s1) with ((a::s0) ++ s1) by reflexivity.
    apply MStarApp.
    - apply H2.
    - apply H3.
  }
Qed.
(** [] *)

(** The definition of our regex matcher will include two fixpoint
    functions. The first function, given regex [re], will evaluate to a
    value that reflects whether [re] matches the empty string. The
    function will satisfy the following property: *)
Definition refl_matches_eps m :=
  forall re : reg_exp ascii, reflect ([ ] =~ re) (m re).

(** **** Exercise: 2 stars, standard, optional (match_eps)

    Complete the definition of [match_eps] so that it tests if a given
    regex matches the empty string: *)
Fixpoint match_eps (re: reg_exp ascii) : bool :=
  match re with
  | EmptySet => false
  | EmptyStr => true
  | Char _ => false
  | App r1 r2 => (match_eps r1) && (match_eps r2)
  | Union r1 r2 => (match_eps r1) || (match_eps r2)
  | Star _ => true
  end.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (match_eps_refl)

    Now, prove that [match_eps] indeed tests if a given regex matches
    the empty string.  (Hint: You'll want to use the reflection lemmas
    [ReflectT] and [ReflectF].) *)
Lemma match_eps_refl : refl_matches_eps match_eps.
Proof.
  unfold refl_matches_eps.
  induction re as [| | c | r1 IHr1 r2 IHr2 | r1 IHr1 r2 IHr2 | re' _ ].
  - apply ReflectF. intros contra. inversion contra.
  - apply ReflectT. constructor.
  - apply ReflectF. intros contra. inversion contra.
  - simpl. 
    apply iff_reflect.
    split.
    + intros H.
      inversion H.
      destruct s1.
      * destruct s2.
        ** inversion IHr1.
           *** inversion IHr2.
                 { reflexivity. }
                 { exfalso. apply H8. apply H4. }
           *** exfalso. apply H6. apply H3.
        ** discriminate H1.
      * discriminate H1.
    + intros H.
      apply andb_true_iff in H.
      destruct H as [H1 H2].
      rewrite H1 in IHr1. inversion IHr1.
      rewrite H2 in IHr2. inversion IHr2.
      replace ([]) with (([] : list ascii) ++ []) by reflexivity.
      apply MApp.
        { apply H. }
        { apply H0. }
  - simpl.
    apply iff_reflect.
    split.
    + intros H.
      inversion H.
      * inversion IHr1.
          { reflexivity. }
          { exfalso. apply H5. apply H2. }
      * inversion IHr2.
        ** destruct (match_eps r1).
             { reflexivity. }
             { reflexivity. }
         ** exfalso. apply H5. apply H1.
    + intros H.
      apply orb_true_iff in H.
      destruct H as [H | H].
      * rewrite H in IHr1.
        inversion IHr1.
        apply MUnionL.
        apply H0.
      * rewrite H in IHr2.
        inversion IHr2.
        apply MUnionR.
        apply H0.
  - apply ReflectT. constructor.
Qed.
(** [] *)

(** We'll define other functions that use [match_eps]. However, the
    only property of [match_eps] that you'll need to use in all proofs
    over these functions is [match_eps_refl]. *)

(** The key operation that will be performed by our regex matcher will
    be to iteratively construct a sequence of regex derivatives. For each
    character [a] and regex [re], the derivative of [re] on [a] is a regex
    that matches all suffixes of strings matched by [re] that start with
    [a]. I.e., [re'] is a derivative of [re] on [a] if they satisfy the
    following relation: *)

Definition is_der re (a : ascii) re' :=
  forall s, a :: s =~ re <-> s =~ re'.

(** A function [d] derives strings if, given character [a] and regex
    [re], it evaluates to the derivative of [re] on [a]. I.e., [d]
    satisfies the following property: *)
Definition derives d := forall a re, is_der re a (d a re).

(** **** Exercise: 3 stars, standard, optional (derive)

    Define [derive] so that it derives strings. One natural
    implementation uses [match_eps] in some cases to determine if key
    regex's match the empty string. *)
Fixpoint derive (a : ascii) (re : reg_exp ascii) : reg_exp ascii :=
  match re with
  | EmptySet =>
    EmptySet
  | EmptyStr =>
    EmptySet
  | Char b =>
    if (a =? b)%char
      then EmptyStr
      else EmptySet
  | App r1 r2 =>
    if (match_eps r1)
      then Union (derive a r2) (App (derive a r1) r2)
      else App (derive a r1) r2
  | Union r1 r2 =>
    Union (derive a r1) (derive a r2)
  | Star r =>
    App (derive a r) (Star r)
  end.
(** [] *)

(** The [derive] function should pass the following tests. Each test
    establishes an equality between an expression that will be
    evaluated by our regex matcher and the final value that must be
    returned by the regex matcher. Each test is annotated with the
    match fact that it reflects. *)
Example c := ascii_of_nat 99.
Example d := ascii_of_nat 100.

(** "c" =~ EmptySet: *)
Example test_der0 : match_eps (derive c (EmptySet)) = false.
Proof.
  simpl. reflexivity.
Qed.

(** "c" =~ Char c: *)
Example test_der1 : match_eps (derive c (Char c)) = true.
Proof.
  simpl. reflexivity.
Qed.

(** "c" =~ Char d: *)
Example test_der2 : match_eps (derive c (Char d)) = false.
Proof.
  simpl. reflexivity.
Qed.

(** "c" =~ App (Char c) EmptyStr: *)
Example test_der3 : match_eps (derive c (App (Char c) EmptyStr)) = true.
Proof.
  simpl. reflexivity.
Qed.

(** "c" =~ App EmptyStr (Char c): *)
Example test_der4 : match_eps (derive c (App EmptyStr (Char c))) = true.
Proof.
  simpl. reflexivity.
Qed.

(** "c" =~ Star c: *)
Example test_der5 : match_eps (derive c (Star (Char c))) = true.
Proof.
  simpl. reflexivity.
Qed.

(** "cd" =~ App (Char c) (Char d): *)
Example test_der6 :
  match_eps (derive d (derive c (App (Char c) (Char d)))) = true.
Proof.
  simpl. reflexivity.
Qed.

(** "cd" =~ App (Char d) (Char c): *)
Example test_der7 :
  match_eps (derive d (derive c (App (Char d) (Char c)))) = false.
Proof.
  simpl. reflexivity.
Qed.

(** **** Exercise: 4 stars, standard, optional (derive_corr)

    Prove that [derive] in fact always derives strings.

    Hint: one proof performs induction on [re], although you'll need
    to carefully choose the property that you prove by induction by
    generalizing the appropriate terms.

    Hint: if your definition of [derive] applies [match_eps] to a
    particular regex [re], then a natural proof will apply
    [match_eps_refl] to [re] and destruct the result to generate cases
    with assumptions that the [re] does or does not match the empty
    string.

    Hint: You can save quite a bit of work by using lemmas proved
    above. In particular, to prove many cases of the induction, you
    can rewrite a [Prop] over a complicated regex (e.g., [s =~ Union
    re0 re1]) to a Boolean combination of [Prop]'s over simple
    regex's (e.g., [s =~ re0 \/ s =~ re1]) using lemmas given above
    that are logical equivalences. You can then reason about these
    [Prop]'s naturally using [intro] and [destruct]. *)

Lemma derive_corr : derives derive.
Proof.
  unfold derives.
  intros a re.
  generalize dependent a.
  induction re as [| | c | r1 IHr1 r2 IHr2 | r1 IHr1 r2 IHr2 | re' IH ].
  - simpl.
    unfold is_der.
    intros a s.
    rewrite null_matches_none. symmetry.
    apply not_equiv_false.
    apply empty_is_empty.
    (* I think the following is simpler here, though *)
    (* split.
      { intros H. inversion H. }
      { intros H. inversion H. } *)
  - simpl. unfold is_der.
    intros a s.
    rewrite empty_nomatch_ne.
    symmetry. apply not_equiv_false.
    apply empty_is_empty.
    (* I think the following is simpler here, though *)
    (* split.
      { intros H. inversion H. }
      { intros H. inversion H. } *)
  - unfold is_der.
    intros a s.
    simpl.
    assert (H : Coq.Bool.Bool.reflect (a = c) ((a =? c)%char)).
      { apply Ascii.eqb_spec. }
    inversion H as [ H1 H2 | H1 H2 ].
    + rewrite H1. rewrite char_eps_suffix. symmetry. apply empty_matches_eps.
    + rewrite null_matches_none. apply char_nomatch_char. apply H1.
  - unfold is_der.
    intros a s.
    assert (H : reflect ([] =~ r1) (match_eps r1)).
      { apply match_eps_refl. }
    split.
    + rewrite app_ne.
      intros [[H1 H2]|[s1 [s2 [H1 [H2 H3]]]]].
      * simpl.
        inversion H as [ H3 H4 | H3 H4 ].
          { apply MUnionL. apply IHr2. apply H2. }
          { exfalso. apply H3. apply H1. }
      * simpl.
        inversion H as [ H4 H5 | H4 H5 ].
          { apply MUnionR. rewrite H1. apply MApp.
            - apply IHr1. apply H2.
            - apply H3. 
          }
          {
            rewrite H1. apply MApp.
            - apply IHr1. apply H2.
            - apply H3.
          }
    + simpl.
      inversion H as [H1 H2 | H1 H2].
      * rewrite union_disj.
        intros [H'|H'].
        ** replace (a::s) with ([] ++ a::s) by reflexivity.
           apply MApp.
            { apply H1. }
            { apply IHr2. apply H'. }
        ** apply app_ne. right.
           apply app_exists in H'.
           destruct H' as [s0 [s1 [H3 [H4 H5]]]].
           exists s0, s1.
           split.
             { apply H3. }
            split.
              { apply IHr1. apply H4. }
              { apply H5. }
      * rewrite app_exists.
        intros [s0 [s1 [H3 [H4 H5]]]].
        apply app_ne.
        right.
        exists s0, s1.
        split.
          { apply H3. }
        split.
          { apply IHr1. apply H4. }
          { apply H5. }
  - unfold is_der.
    intros a s.
    rewrite union_disj.
    split.
    + intros [H|H].
      * simpl. apply MUnionL. apply IHr1. apply H.
      * simpl. apply MUnionR. apply IHr2. apply H.
    + simpl.
      rewrite union_disj.
      intros [H|H].
      * left. apply IHr1. apply H.
      * right. apply IHr2. apply H.
  - unfold is_der.
    intros a s.
    rewrite star_ne.
    split.
    + intros [s0 [s2 [H1 [H2 H3]]]].
      simpl.
      rewrite H1.
      apply MApp.
      * apply IH. apply H2.
      * apply H3.
    + simpl.
      rewrite app_exists.
      intros [s0 [s1 [H1 [H2 H3]]]].
      exists s0, s1.
      split.
        { apply H1. }
      split.
        { apply IH. apply H2. }
        { apply H3. }
Qed.
(** [] *)

(** We'll define the regex matcher using [derive]. However, the only
    property of [derive] that you'll need to use in all proofs of
    properties of the matcher is [derive_corr]. *)

(** A function [m] matches regexes if, given string [s] and regex [re],
    it evaluates to a value that reflects whether [s] is matched by
    [re]. I.e., [m] holds the following property: *)
Definition matches_regex m : Prop :=
  forall (s : string) re, reflect (s =~ re) (m s re).

(** **** Exercise: 2 stars, standard, optional (regex_match)

    Complete the definition of [regex_match] so that it matches
    regexes. *)
Fixpoint regex_match (s : string) (re : reg_exp ascii) : bool :=
  match s with
  | [] =>
    match_eps re
  | c::s' =>
    regex_match s' (derive c re)
  end.
(** [] *)

(** **** Exercise: 3 stars, standard, optional (regex_refl)

    Finally, prove that [regex_match] in fact matches regexes.

    Hint: if your definition of [regex_match] applies [match_eps] to
    regex [re], then a natural proof applies [match_eps_refl] to [re]
    and destructs the result to generate cases in which you may assume
    that [re] does or does not match the empty string.

    Hint: if your definition of [regex_match] applies [derive] to
    character [x] and regex [re], then a natural proof applies
    [derive_corr] to [x] and [re] to prove that [x :: s =~ re] given
    [s =~ derive x re], and vice versa. *)
Theorem regex_refl : matches_regex regex_match.
Proof.
  unfold matches_regex.
  intros s re.
  generalize dependent re.
  induction s as [| c s' IH ].
  - intros re.
    simpl.
    apply match_eps_refl.
  - intros re.
    simpl.
    assert (H : reflect (s' =~ derive c re) (regex_match s' (derive c re))).
      { apply IH. }
    inversion H as [ H1 H2 | H1 H2 ].
    + apply ReflectT.
      apply derive_corr.
      apply H1.
    + apply ReflectF.
      intros H'.
      apply H1.
      apply derive_corr.
       apply H'.
Qed.
(** [] *)

(* 2021-08-11 15:08 *)
