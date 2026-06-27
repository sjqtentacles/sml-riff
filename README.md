# sml-riff

[![CI](https://github.com/sjqtentacles/sml-riff/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-riff/actions/workflows/ci.yml)

RIFF (Resource Interchange File Format) chunk reader/writer for Standard ML.
RIFF is the container format used by WAV audio, AVI video, and WebP images.

## API sketch

```sml
(* Encode a list of chunks to a binary string *)
val bytes : string = Riff.encode [
  { id = "fmt ", data = fmtData },
  { id = "data", data = audioSamples }
]

(* Decode a binary string back to chunk list *)
val chunks : Riff.chunk list = Riff.decode bytes

(* Access chunk fields *)
val { id, data } = List.hd chunks
```

## Nested containers (tree API)

Real RIFF files (WAV with `LIST`/`INFO`, AVI, WebP) nest chunks inside `RIFF`
and `LIST` containers. The tree API models that directly:

```sml
datatype node =
    Leaf of { id : string, data : string }
  | Container of { tag : string, form : string, children : node list }

val tree = Riff.parseTree bytes      (* recursive descent into RIFF/LIST *)
val bytes' = Riff.encodeTree tree    (* inverse for well-formed input *)

Riff.formOf tree                     (* SOME "WAVE" *)
Riff.find "fmt " tree                (* first matching leaf, depth-first *)
Riff.findAll "IART" tree             (* every matching leaf *)
```

`parseTree` raises `Riff.Format` on a bad magic, a truncated header, a
container too small to hold its form 4cc, or a declared size that overruns the
buffer.

## Format details

Each chunk has a 4-byte ASCII id, a 4-byte little-endian size, and a data
payload. Chunks are padded to even byte boundaries per the RIFF specification.
`decode` raises `Riff.Format` on truncated or malformed input.

## Known limitations

- **Two-level API**: the flat `encode`/`decode` handle a single level of chunks
  (with a hardcoded `"WAVE"` form on encode). For full WAV/AVI/WebP structure
  use the tree API (`parseTree`/`encodeTree`) which descends recursively into
  `RIFF`/`LIST` containers and preserves the form/list 4cc.
- **No endianness conversion**: data payloads are passed through as-is. It is
  the caller's responsibility to pack/unpack multi-byte values correctly.
- **Maximum chunk size**: limited by `Int.maxInt`; not suitable for chunks > 2 GB
  on 32-bit platforms.

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-riff
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-riff/riff.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-riff/
  riff.sig     RIFF signature (flat + tree API)
  riff.sml     encode/decode + parseTree/encodeTree/find with strict validation
  riff.mlb
test/
  test.sml     round-trip, nested LIST, find/findAll, strict validation
```

## License

MIT. See [LICENSE](LICENSE).
