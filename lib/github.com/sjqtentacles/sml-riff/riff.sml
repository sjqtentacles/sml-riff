structure Riff :> RIFF =
struct
  type chunk = { id : string, data : string }
  exception Format of string

  datatype node =
      Leaf of chunk
    | Container of { tag : string, form : string, children : node list }

  fun pad4 n = if n mod 2 = 1 then n + 1 else n

  fun pow256 0 = 1 | pow256 i = 256 * pow256 (i - 1)

  fun u32 n =
    Buffer.build (fn b =>
      let fun byte i = Buffer.addChar b (Char.chr ((n div pow256 i) mod 256))
      in List.app byte [0,1,2,3] end)

  fun readU32 s off =
    let fun b i = Char.ord (String.sub (s, off + i))
    in b 0 + 256 * b 1 + 65536 * b 2 + 16777216 * b 3 end

  fun encodeChunk { id, data } =
    let val sz = String.size data
        val body = if sz mod 2 = 1 then data ^ "\000" else data
    in id ^ u32 sz ^ body end

  fun encode chunks =
    let val body = String.concat (List.map encodeChunk chunks)
    in "RIFF" ^ u32 (String.size body + 4) ^ "WAVE" ^ body end

  fun decode s =
    if String.size s < 12 orelse String.substring (s, 0, 4) <> "RIFF" then raise Format "not RIFF"
    else
      let
        fun readChunks off stop acc =
          if off + 8 > stop then rev acc
          else
            let
              val id = String.substring (s, off, 4)
              val sz = readU32 s (off + 4)
              val data = String.substring (s, off + 8, sz)
              val next = off + 8 + pad4 sz
            in readChunks next stop ({ id = id, data = data } :: acc) end
        val riffSize = readU32 s 4
      in readChunks 12 (8 + riffSize) [] end

  (* --- nested (tree) API --- *)

  fun isContainerTag t = (t = "RIFF" orelse t = "LIST")

  (* Parse a chunk at offset `off`, returning (node, nextOffset). `stop` is the
     exclusive byte limit this chunk must not exceed. *)
  fun parseChunkAt s stop off =
    let
      val () = if off + 8 > stop then raise Format "truncated chunk header" else ()
      val tag = String.substring (s, off, 4)
      val sz = readU32 s (off + 4)
      val bodyStart = off + 8
      val () = if sz < 0 orelse bodyStart + sz > stop
               then raise Format ("chunk '" ^ tag ^ "' overruns buffer") else ()
      val next = bodyStart + pad4 sz
    in
      if isContainerTag tag then
        let
          val () = if sz < 4 then raise Format ("container '" ^ tag ^ "' too small for form") else ()
          val form = String.substring (s, bodyStart, 4)
          val childStop = bodyStart + sz
          fun loop o2 acc =
            if o2 + 8 > childStop then List.rev acc
            else
              let val (child, o3) = parseChunkAt s childStop o2
              in loop o3 (child :: acc) end
          val children = loop (bodyStart + 4) []
        in (Container { tag = tag, form = form, children = children }, next) end
      else
        let val data = String.substring (s, bodyStart, sz)
        in (Leaf { id = tag, data = data }, next) end
    end

  fun parseTree s =
    if String.size s < 8 then raise Format "too short for a RIFF header"
    else
      let val tag = String.substring (s, 0, 4)
          val () = if tag <> "RIFF" then raise Format "not a RIFF file" else ()
          val (node, _) = parseChunkAt s (String.size s) 0
      in node end

  fun encodeTree node =
    case node of
        Leaf c => encodeChunk c
      | Container { tag, form, children } =>
          let val body = form ^ String.concat (List.map encodeTree children)
          in tag ^ u32 (String.size body) ^ body end

  (* depth-first traversal collecting matching leaves *)
  fun foldLeaves f init node =
    case node of
        Leaf c => f (c, init)
      | Container { children, ... } =>
          List.foldl (fn (child, acc) => foldLeaves f acc child) init children

  fun findAll id node =
    List.rev (foldLeaves (fn (c, acc) => if #id c = id then c :: acc else acc) [] node)

  fun find id node =
    case findAll id node of [] => NONE | c :: _ => SOME c

  fun formOf node =
    case node of
        Leaf _ => NONE
      | Container { form, ... } => SOME form
end

