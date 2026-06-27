(* riff.sig — RIFF chunk reader/writer. *)

signature RIFF =
sig
  type chunk = { id : string, data : string }
  exception Format of string

  (* --- flat API (unchanged) --- *)
  val encode : chunk list -> string
  val decode : string -> chunk list

  (* --- nested (tree) API --- *)

  (* A RIFF tree: either a leaf chunk (4cc id + raw data) or a container
     ("RIFF" or "LIST") carrying a 4-byte form/list type and ordered children.
     Containers nest arbitrarily. *)
  datatype node =
      Leaf of chunk
    | Container of { tag : string      (* "RIFF" or "LIST" *)
                   , form : string     (* the form / list type 4cc *)
                   , children : node list }

  (* Parse a whole RIFF byte string into a tree, recursively descending into
     "RIFF"/"LIST" containers. Raises Format on a bad magic, a truncated
     header/body, or a declared size that overruns the buffer. *)
  val parseTree : string -> node

  (* Serialize a tree back to bytes (inverse of parseTree for well-formed
     input; even-byte padding is reapplied). *)
  val encodeTree : node -> string

  (* Depth-first search for the first leaf chunk with the given id. *)
  val find : string -> node -> chunk option

  (* All leaf chunks with the given id, in depth-first order. *)
  val findAll : string -> node -> chunk list

  (* The form/list 4cc of a container (NONE for a leaf). *)
  val formOf : node -> string option
end
