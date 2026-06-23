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
  in Harness.run () end
end
