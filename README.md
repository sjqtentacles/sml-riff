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

## Format details

Each chunk has a 4-byte ASCII id, a 4-byte little-endian size, and a data
payload. Chunks are padded to even byte boundaries per the RIFF specification.
`decode` raises `Riff.Format` on truncated or malformed input.

## Known limitations

- **No RIFF/LIST nesting**: the library encodes and decodes flat chunk lists
  only. Nested `RIFF` and `LIST` container chunks (required for full WAV/AVI
  compliance) are not automatically parsed — the `data` field of a `RIFF`
  chunk is returned as a raw string that you can pass back to `decode`
  recursively if needed.
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
  riff.sig     RIFF signature
  riff.sml     encode/decode implementation
  riff.mlb
test/
  test.sml     round-trip and error-case tests
```

## License

MIT. See [LICENSE](LICENSE).
