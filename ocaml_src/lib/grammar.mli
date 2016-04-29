(* camlp5r *)
(* grammar.mli,v *)
(* Copyright (c) INRIA 2007-2016 *)

(** Extensible grammars.

    This module implements the Camlp5 extensible grammars system.
    Grammars entries can be extended using the [EXTEND] statement,
    added by loading the Camlp5 [pa_extend.cmo] file. *)

type g;;
   (** The type for grammars, holding entries. *)
type token = string * string;;

val gcreate : token Plexing.lexer -> g;;
   (** Create a new grammar, without keywords, using the lexer given
       as parameter. *)
val tokens : g -> string -> (string * int) list;;
   (** Given a grammar and a token pattern constructor, returns the list of
       the corresponding values currently used in all entries of this grammar.
       The integer is the number of times this pattern value is used.

       Examples:
-      The call [Grammar.tokens g ""] returns the keywords list.
-      The call [Grammar.tokens g "IDENT"] returns the list of all usages
       of the pattern "IDENT" in the [EXTEND] statements. *)
val glexer : g -> token Plexing.lexer;;
   (** Return the lexer used by the grammar *)

type parsable;;
val parsable : g -> char Stream.t -> parsable;;
   (** Type and value allowing to keep the same token stream between
       several calls of entries of the same grammar, to prevent possible
       loss of tokens. To be used with [Entry.parse_parsable] below *)

module Entry :
  sig
    type 'a e;;
    val create : g -> string -> 'a e;;
    val parse : 'a e -> char Stream.t -> 'a;;
    val parse_all : 'a e -> char Stream.t -> 'a list;;
    val parse_token : 'a e -> token Stream.t -> 'a;;
    val parse_parsable : 'a e -> parsable -> 'a;;
    val name : 'a e -> string;;
    val of_parser : g -> string -> (token Stream.t -> 'a) -> 'a e;;
    val print : Format.formatter -> 'a e -> unit;;
    val find : 'a e -> string -> Obj.t e;;
    external obj : 'a e -> token Gramext.g_entry = "%identity";;
  end
;;
   (** Module to handle entries.
-      [Entry.e] is the type for entries returning values of type ['a].
-      [Entry.create g n] creates a new entry named [n] in the grammar [g].
-      [Entry.parse e] returns the stream parser of the entry [e].
-      [Entry.parse_all e] returns the stream parser returning all possible
          values while parsing with the entry [e]: may return more than one
          value when the parsing algorithm is [Backtracking]
-      [Entry.parse_all e] returns the parser returning all possible values.
-      [Entry.parse_token e] returns the token parser of the entry [e].
-      [Entry.parse_parsable e] returns the parsable parser of the entry [e].
-      [Entry.name e] returns the name of the entry [e].
-      [Entry.of_parser g n p] makes an entry from a token stream parser.
-      [Entry.print e] displays the entry [e] using [Format].
-      [Entry.find e s] finds the entry named [s] in the rules of [e].
-      [Entry.obj e] converts an entry into a [Gramext.g_entry] allowing
          to see what it holds. *)

val of_entry : 'a Entry.e -> g;;
   (** Return the grammar associated with an entry. *)

(** {6 Clearing grammars and entries} *)

module Unsafe :
  sig
    val gram_reinit : g -> token Plexing.lexer -> unit;;
    val clear_entry : 'a Entry.e -> unit;;
  end
;;
   (** Module for clearing grammars and entries. To be manipulated with
       care, because: 1) reinitializing a grammar destroys all tokens
       and there may have problems with the associated lexer if there
       are keywords; 2) clearing an entry does not destroy the tokens
       used only by itself.
-      [Unsafe.reinit_gram g lex] removes the tokens of the grammar
-      and sets [lex] as a new lexer for [g]. Warning: the lexer
-      itself is not reinitialized.
-      [Unsafe.clear_entry e] removes all rules of the entry [e]. *)

(** {6 Parsing algorithm} *)

type parse_algorithm =
  Gramext.parse_algorithm = Predictive | Backtracking | DefaultAlgorithm
;;
   (** Type of algorithm used in grammar entries.
         [Predictive]: use imperative streams with predictive parsing
         [Backtracking]: use functional streams with full backtracking
         [DefaultAlgorithm]: found in the variable [backtrack_parse] below.
       The default, when a grammar is created, is [DefaultAlgorithm]. *)

val set_algorithm : g -> parse_algorithm -> unit;;
   (** Set the parsing algorithm for all entries of a given grammar. *)

val backtrack_parse : bool ref;;
   (** If [True], the default parsing uses full backtracking. If [False],
       it uses parsing with normal streams. If the environment variable
       CAMLP5PARAM contains "b", the default is [True]; otherwise, the
       default is [False]. *)

val backtrack_stalling_limit : int ref;;
   (** Limitation of backtracking to prevent stalling in case of syntax
       error. In backtracking algorithm, when there is a syntax error,
       the parsing continues trying to find another solution. It some
       grammars, it can be very long before checking all possibilities.
       This number limits the number of tokens tests after a backtrack.
       (The number of tokens tests is reset to zero when the token
       stream overtakes the last reached token.) The default is 10000.
       If set to 0, there is no limit. Can be set by the environment
       variable CAMLP5PARAM by "l=value". *)

(** {6 Functorial interface} *)

   (** Alternative for grammars use. Grammars are no more Ocaml values:
       there is no type for them. Modules generated preserve the
       rule "an entry cannot call an entry of another grammar" by
       normal OCaml typing. *)

module type GLexerType = sig type te;; val lexer : te Plexing.lexer;; end;;
   (** The input signature for the functor [Grammar.GMake]: [te] is the
       type of the tokens. *)

module type S =
  sig
    type te;;
    type parsable;;
    val parsable : char Stream.t -> parsable;;
    val tokens : string -> (string * int) list;;
    val glexer : te Plexing.lexer;;
    val set_algorithm : parse_algorithm -> unit;;
    module Entry :
      sig
        type 'a e;;
        val create : string -> 'a e;;
        val parse : 'a e -> parsable -> 'a;;
        val parse_token : 'a e -> te Stream.t -> 'a;;
        val name : 'a e -> string;;
        val of_parser : string -> (te Stream.t -> 'a) -> 'a e;;
        val print : Format.formatter -> 'a e -> unit;;
        external obj : 'a e -> te Gramext.g_entry = "%identity";;
      end
    ;;
    module Unsafe :
      sig
        val gram_reinit : te Plexing.lexer -> unit;;
        val clear_entry : 'a Entry.e -> unit;;
      end
    ;;
    val extend :
      'a Entry.e -> Gramext.position option ->
        (string option * Gramext.g_assoc option *
           (te Gramext.g_symbol list * Gramext.g_action) list)
          list ->
        unit;;
    val delete_rule : 'a Entry.e -> te Gramext.g_symbol list -> unit;;
  end
;;
   (** Signature type of the functor [Grammar.GMake]. The types and
       functions are almost the same than in generic interface, but:
-      Grammars are not values. Functions holding a grammar as parameter
         do not have this parameter yet.
-      The type [parsable] is used in function [parse] instead of
         the char stream, avoiding the possible loss of tokens.
-      The type of tokens (expressions and patterns) can be any
         type (instead of (string * string)); the module parameter
         must specify a way to show them as (string * string) *)

module GMake (L : GLexerType) : S with type te = L.te;;

(** {6 Miscellaneous} *)

val skip_item : 'a -> 'a;;
   (** [Grammar.skip_item x] can be called in a semantic action of
       a grammar rule to ask the grammar to skip that item if it
       is called in a list (LIST0 or LIST1). The function returns
       the item itself (for typing reasons) but its value is ignored.
       This function is used to allow IFDEF and IFNDEF for cases of
       constructor declarations and pattern matchings. *)

val error_verbose : bool ref;;
   (** Flag for displaying more information in case of parsing error;
       default = [False] *)

val warning_verbose : bool ref;;
   (** Flag for displaying warnings while extension; default = [True] *)

val strict_parsing : bool ref;;
   (** Flag to apply strict parsing, without trying to recover errors;
       default = [False] *)

val utf8_print : bool ref;;
   (** Flag to consider strings as utf8-encoded when printing them;
       default = [True] *)

val print_entry : Format.formatter -> 'te Gramext.g_entry -> unit;;
   (** General printer for all kinds of entries (obj entries) *)

val iter_entry :
  ('te Gramext.g_entry -> unit) -> 'te Gramext.g_entry -> unit;;
  (** [Grammar.iter_entry f e] applies [f] to the entry [e] and
      transitively all entries called by [e]. The order in which
      the entries are passed to [f] is the order they appear in
      each entry. Each entry is passed only once. *)

val fold_entry :
  ('te Gramext.g_entry -> 'a -> 'a) -> 'te Gramext.g_entry -> 'a -> 'a;;
  (** [Grammar.fold_entry f e init] computes [(f eN .. (f e2 (f e1 init)))],
      where [e1 .. eN] are [e] and transitively all entries called by [e].
      The order in which the entries are passed to [f] is the order they
      appear in each entry. Each entry is passed only once. *)

val reinit_entry_functions : 'te Gramext.g_entry -> unit;;

(*** For system use *)

val loc_of_token_interval : int -> int -> Ploc.t;;
val extend :
  ('te Gramext.g_entry * Gramext.position option *
     (string option * Gramext.g_assoc option *
        ('te Gramext.g_symbol list * Gramext.g_action) list)
       list)
    list ->
    unit;;
val delete_rule : 'a Entry.e -> token Gramext.g_symbol list -> unit;;

val parse_top_symb :
  'te Gramext.g_entry -> 'te Gramext.g_symbol -> 'te Stream.t -> Obj.t;;
val symb_failed_txt :
  'te Gramext.g_entry -> 'te Gramext.g_symbol -> 'te Gramext.g_symbol ->
    string;;
val create_local_entry : g -> string -> 'a Entry.e;;
