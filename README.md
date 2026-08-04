# eb-haiku

A binding for [Haiku OS](https://www.haiku-os.org/)'s own native API (the
"Kits") for [eBasic](https://github.com/yann64/ebasic), managed with
`ebpm`.

**This package only builds and runs on real Haiku** - it links against
`libbe.so`, which doesn't exist anywhere else. There is no local/CI
verification path; see [Verifying](#verifying) below.

## Why

Haiku's Kits (Storage, Support, Application, Interface, ...) are the
OS's own real API - most distinctively, every file can carry arbitrary
named, typed **extended attributes** (Haiku's own `BNode`/`BNodeInfo`),
a real OS capability with no POSIX equivalent and no overlap with
eBasic's own core [File Library](https://github.com/yann64/ebasic/blob/main/docs/reference/file-library.md)
(plain byte-level read/write).

## Status: Phase 1 (no GUI subclassing)

Unlike GTK4 (a C library `eb-gtk4` binds directly, with a C-shaped
object/signal system) or cJSON (`eb-cjson`'s own target, also a plain C
library), **Haiku's Kits have no C-level API at all** - `BPath`,
`BEntry`, `BMessage`, `BApplication`, etc. are only reachable as real
C++ classes with mangled symbol names, and eBasic's `Extern` mechanism
only ever binds free functions (never a foreign class's constructor or
methods). So this package's own `native/` directory is a small,
hand-written `extern "C"` shim - real C++ that constructs/calls/
destroys the actual Haiku objects internally and exposes a flat,
unmangled ABI eBasic can bind to.

**Phase 1** (this package, today) covers everything usable without
subclassing or overriding a virtual method:

- **Storage Kit**: `BPath`, `BEntry`, `BDirectory`, and `BNode`/
  `BNodeInfo` (extended attributes + MIME type) - see `src/path.bas`,
  `src/entry.bas`, `src/directory.bas`, `src/node.bas`.
- **Support Kit**: `BMessage` - see `src/message.bas`.
- **Application Kit**: `BApplication`'s basic lifecycle (construct,
  `Run`, `Quit`) - see `src/application.bas`.

**Explicitly out of scope for Phase 1**: `BWindow`/`BView` subclassing
and any real GUI (overriding `Draw`/`MessageReceived`/etc. from eBasic
would need the shim to define real C++ subclasses forwarding virtual
calls to stored callbacks - a substantially larger, separate effort).
Without a subclassed `MessageReceived`, a running `HApplication` mostly
just registers with the system and idles until quit - real and
testable, but not yet "build an interactive app."

Two `.bas` layers, matching `eb-cjson`'s own convention:

- **Raw layer** (`src/raw/haiku_shim.bas`) - `Extern "C" Lib
  "ebhaikushim"` declarations mirroring `native/shim.h`'s real C ABI
  1:1. Every Haiku object lives behind an opaque `ANY PTR` handle.
- **Idiomatic layer** (`src/path.bas`/`entry.bas`/`directory.bas`/
  `node.bas`/`message.bas`/`application.bas`) - `HPath`/`HEntry`/
  `HDirectory`/`HNode`/`HNodeInfo`/`HMessage`/`HApplication`, each a
  thin `TYPE ... : handle AS ANY PTR : END TYPE` wrapper plus free
  functions. Every parameter is explicitly `BYVAL` - each is just an
  8-byte handle, cheap to copy.

## Known gaps

- **No top-level `STRING`-returning function can cross an `ebpm --lib`
  package boundary yet** (the same restriction `eb-gtk4`/`eb-cjson`
  already hit) - `HNodeReadAttrString`/`HNodeGetNextAttrName`/
  `HNodeInfoGetType` return a raw, freshly-heap-allocated `ANY PTR`
  instead (freed via `HFreeString`), matching `eb-cjson`'s own
  `JsonStringify`/`JsonFreeString` fix for exactly the same issue.
- **Linking against this package requires `-l be` explicitly**, in
  addition to the `-l ebhaikushim` `ebpm` already forwards
  automatically (via its own `.libs` sidecar mechanism) - `libbe` is a
  transitive dependency of the *shim's own internals*, not something
  any `Lib` clause in this package's `.bas` source captures (`ebpm`'s
  `Lib`-clause forwarding only sees symbols a package's own `Extern`
  blocks actually declare). `libbe.so` is always present on any real
  Haiku system, so this is a one-line addition wherever you invoke
  `ebc` directly, not a real installation burden - but it's not yet
  automatic. See `scripts/haiku_verify.sh` for the exact invocation.

## Building

The native shim isn't compiled by `ebpm` (neither `ebc` nor `ebpm`
compiles a package's own native code today) - build and install it
once, directly:

```sh
cmake -S native -B native/build
cmake --build native/build
cp native/build/libebhaikushim.a /boot/system/non-packaged/develop/lib/
```

Then, on real Haiku, with `ebc`/`ebpm` installed:

```sh
ebpm build   # archives the .bas layer only - no linking needed
```

To compile a real program against this package (until it's published -
see below), link explicitly:

```sh
ebc yourprogram.bas -o yourprogram -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be
```

## Verifying

```sh
scripts/haiku_verify.sh [ssh-host]   # default host: haiku
```

Builds the shim, runs `ebpm build`, then compiles and runs
`tests/integration.bas` (every Phase 1 function, against real
filesystem state) on the given SSH host - mirroring eBasic's own
`scripts/haiku_verify.sh`.

## Using as a dependency

Once published:

```toml
[dependencies]
eb-haiku = "^0.1"
```

```basic
#include "eb-haiku.iface.bas"

DIM p AS HPath
p = HPathCreate("/boot/home/notes.txt")
PRINT HPathLeaf(p)   ' notes.txt
CALL HPathFree(p)

DIM node AS HNode
node = HNodeCreate("/boot/home/notes.txt")
CALL HNodeWriteAttrString(node, "Author", "eBasic")
DIM raw AS ANY PTR
raw = HNodeReadAttrString(node, "Author")
IF raw <> 0 THEN
    DIM z AS ZSTRING : z = raw
    DIM author AS STRING : author = z
    PRINT author       ' eBasic
    CALL HFreeString(raw)
END IF
CALL HNodeFree(node)
```

(Consuming programs still need `-l be` at their own final link step -
see Known Gaps above.)

## Layout

- `native/` - the hand-written C++ shim (see above); its own standalone
  `CMakeLists.txt`, not driven by `ebpm`.
- `src/raw/` - the raw FFI layer.
- `src/*.bas` (excluding `raw/`) - the idiomatic layer; `src/lib.bas` is
  the package's `#include` aggregator (its own `[lib]` entry point).
- `examples/` - one small, focused example per Kit area, each run for
  real on Haiku hardware.
- `tests/integration.bas` - a single comprehensive test exercising
  every Phase 1 function against real Haiku state, run via
  `scripts/haiku_verify.sh` (not `ebpm test` - see Known Gaps above on
  why linking a final executable needs `-l be` explicitly).
