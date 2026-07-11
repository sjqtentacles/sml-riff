(* demo.sml - build and inspect a small RIFF container (the chunk format
   used by WAV/AVI/etc) via both the flat chunk-list API and the nested
   tree API. Deterministic: identical output on every run and both
   compilers. *)

structure R = Riff

val () = print "Flat API: encode/decode a chunk list:\n"
val chunks = [ { id = "fmt ", data = "PCM!" }
             , { id = "data", data = "HELLOHI!" } ]
val bytes = R.encode chunks
val () = print ("  encoded " ^ Int.toString (String.size bytes) ^ " bytes\n")
val decoded = R.decode bytes
val () =
  List.app
    (fn { id, data } => print ("  chunk '" ^ id ^ "' = \"" ^ data ^ "\"\n"))
    decoded

val () = print "\nTree API: nested RIFF/LIST containers:\n"
val tree =
  R.Container
    { tag = "RIFF", form = "WAVE"
    , children =
        [ R.Leaf { id = "fmt ", data = "PCM!" }
        , R.Container
            { tag = "LIST", form = "INFO"
            , children = [ R.Leaf { id = "INAM", data = "DemoWav" } ] }
        , R.Leaf { id = "data", data = "HELLOHI!" }
        ] }
val treeBytes = R.encodeTree tree
val () = print ("  encodeTree -> " ^ Int.toString (String.size treeBytes) ^ " bytes\n")
val roundTrip = R.parseTree treeBytes
val () = print ("  parseTree round-trip formOf root = "
                ^ (case R.formOf roundTrip of SOME f => f | NONE => "?") ^ "\n")
val () =
  case R.find "INAM" roundTrip of
      SOME { data, ... } => print ("  find \"INAM\" -> \"" ^ data ^ "\"\n")
    | NONE => print "  find \"INAM\" -> not found\n"
val () =
  print ("  findAll \"fmt \" -> "
        ^ Int.toString (List.length (R.findAll "fmt " roundTrip)) ^ " match(es)\n")
