structure Tests =
struct
  open Harness
  structure R = Riff
  fun run () =
  let
    val chunks = [ { id = "fmt ", data = "PCM" }, { id = "data", data = "abcd" } ]
    val () = section "round-trip"
    val enc = R.encode chunks
    val dec = R.decode enc
    val () = checkInt "chunk count" (2, List.length dec)
    val () = checkString "first id" ("fmt ", #id (List.nth (dec, 0)))
    val () = checkString "data payload" ("abcd", #data (List.nth (dec, 1)))
    val () = checkRaises "bad magic" (fn () => ignore (R.decode "NOPE"))

    val () = section "tree round-trip (nested LIST)"
    (* RIFF(WAVE) { fmt , LIST(INFO){ IART, INAM }, data } *)
    val tree =
      R.Container
        { tag = "RIFF", form = "WAVE"
        , children =
            [ R.Leaf { id = "fmt ", data = "PCM" }
            , R.Container
                { tag = "LIST", form = "INFO"
                , children =
                    [ R.Leaf { id = "IART", data = "artist" }
                    , R.Leaf { id = "INAM", data = "name" } ] }
            , R.Leaf { id = "data", data = "abcd" } ] }
    val encTree = R.encodeTree tree
    val parsed = R.parseTree encTree
    val () = checkBool "top form WAVE" (true, R.formOf parsed = SOME "WAVE")

    val () = section "find / findAll across nesting"
    val () = (case R.find "fmt " parsed of
                  SOME c => checkString "find fmt data" ("PCM", #data c)
                | NONE => checkBool "find fmt" (true, false))
    val () = (case R.find "IART" parsed of
                  SOME c => checkString "find nested IART" ("artist", #data c)
                | NONE => checkBool "find IART" (true, false))
    val () = checkBool "find missing -> NONE" (true, R.find "zzzz" parsed = NONE)
    val () = checkInt "findAll leaves total via data" (4,
               List.length (R.findAll "fmt " parsed
                          @ R.findAll "IART" parsed
                          @ R.findAll "INAM" parsed
                          @ R.findAll "data" parsed))

    val () = section "nested container structure preserved"
    val () = (case parsed of
                  R.Container { children, ... } =>
                    (checkInt "top has 3 children" (3, List.length children);
                     case List.nth (children, 1) of
                         R.Container { form, children = gk, ... } =>
                           (checkBool "inner is INFO" (true, form = "INFO");
                            checkInt "inner has 2 leaves" (2, List.length gk))
                       | R.Leaf _ => checkBool "inner is container" (true, false))
                | R.Leaf _ => checkBool "top is container" (true, false))

    val () = section "strict validation"
    val () = checkRaises "parseTree bad magic" (fn () => ignore (R.parseTree "NOPExxxx"))
    val () = checkRaises "parseTree too short" (fn () => ignore (R.parseTree "RIF"))
    (* declared size overruns the buffer *)
    val overrun = "RIFF" ^ "\255\255\255\127" ^ "WAVE"
    val () = checkRaises "parseTree overrun" (fn () => ignore (R.parseTree overrun))
  in Harness.run () end
end
