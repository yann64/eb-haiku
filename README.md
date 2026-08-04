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

## Status

Unlike GTK4 (a C library `eb-gtk4` binds directly, with a C-shaped
object/signal system) or cJSON (`eb-cjson`'s own target, also a plain C
library), **Haiku's Kits have no C-level API at all** - `BPath`,
`BWindow`, `BApplication`, etc. are only reachable as real C++ classes
with mangled symbol names, and eBasic's `Extern` mechanism only ever
binds free functions (never a foreign class's constructor or methods).
So this package's own `native/` directory is a small, hand-written
`extern "C"` shim - real C++ that constructs/calls/destroys the actual
Haiku objects internally and exposes a flat, unmangled ABI eBasic can
bind to.

**Phase 1**: Storage Kit (`BPath`/`BEntry`/`BDirectory`/`BNode`+
`BNodeInfo`), Support Kit (`BMessage`), `BApplication`'s basic
lifecycle - see `src/path.bas`, `src/entry.bas`, `src/directory.bas`,
`src/node.bas`, `src/message.bas`, `src/application.bas`.

**Phase 2 (GUI)**: real windows, custom drawing, and stock controls -
`BWindow`/`BView` reached via real C++ shim subclasses (`ShimWindow`/
`ShimView` in `native/shim_interface.cpp`) forwarding
`MessageReceived`/`QuitRequested`/`FrameResized`/`Draw`/`MouseDown`/
`MouseUp`/`KeyDown` to eBasic callbacks - see `src/window.bas`,
`src/view.bas`. Stock controls (`BButton`/`BStringView`/`BTextControl`,
`src/controls.bas`) need no callback-forwarding shim of their own:
Haiku's own `BControl`/`BInvoker` already posts a control's own `what`
message to its target (the window it's attached to, once shown), so a
button click arrives at the *window's* `MessageReceived` callback, not
a separate per-control one. `BGroupLayout` (`src/layout.bas`) arranges
children automatically instead of manual frame positioning.

**Explicitly out of scope**: overriding `BView`/`BWindow` methods
beyond the specific set above (e.g. `AttachedToWindow`, drag-and-drop),
and any layout besides `BGroupLayout` (`BLayoutBuilder`'s templated API
is a possible future addition).

### Threading - read this before writing a GUI program

`BApplication::Run()` blocks whichever thread calls it. Each `BWindow`,
once shown, runs its own message loop on its own separate thread - so
a program with even a single window already involves two threads, and
every window/view callback (`HWindowSetMessageReceivedCallback`,
`HShimViewSetDrawCallback`, etc.) is invoked from *that window's own
thread*, never the thread that called `HApplicationRun`. eBasic has no
locking primitives.

**The safe, intended usage pattern**: the thread that calls
`HApplicationRun` does nothing else afterward - all real program logic
lives inside the window/app-level callbacks, which Haiku's own
per-window message queue already serializes one at a time. Multiple
simultaneous windows each get their own thread; if their callbacks ever
need to touch shared state, that's a real, unsolved risk this package
doesn't protect you from.

**A related, sharper trap, found the hard way**: several real Haiku
`BView`/`BWindow`/`BInvoker` methods (`BInvoker::Invoke()`,
`BView::Invalidate()` - confirmed by direct reproduction in standalone
C++ programs with no eBasic involved at all, kernel fault backtraces
pointing squarely at the method itself) **crash** if called from
outside the target's own thread without care. This package's own shim
already handles the ones it exposes correctly (`HButtonInvoke` posts via
`Messenger()` instead of calling `Invoke()`; `HShimViewInvalidate` locks
the window first) - but if you ever call a raw Haiku function yourself
from outside a window's own callback, assume it needs the same care.

## Two `.bas` layers

Matching `eb-cjson`'s own convention:

- **Raw layer** (`src/raw/*.bas`) - `Extern "C" Lib "ebhaikushim"`/
  `Lib "be"` declarations mirroring the shim's (or Haiku's own, for
  `find_directory`) real C ABI 1:1. Every Haiku object lives behind an
  opaque `ANY PTR` handle. `BRect` is a plain public 4-`float` struct in
  real Haiku - passed as 4 separate floats throughout, not mirrored as
  its own handle/`TYPE`.
- **Idiomatic layer** (`src/*.bas`, excluding `raw/`) - `HPath`/
  `HEntry`/`HDirectory`/`HNode`/`HNodeInfo`/`HMessage`/`HApplication`/
  `HWindow`/`HView`/`HShimView`/`HButton`/`HStringView`/`HTextControl`/
  `HGroupLayout`, each a thin `TYPE ... : handle AS ANY PTR : END TYPE`
  wrapper plus free functions. Every parameter is explicitly `BYVAL` -
  each is just an 8-byte handle, cheap to copy.

## Known gaps

- **No top-level `STRING`-returning function can cross an `ebpm --lib`
  package boundary yet** (the same restriction `eb-gtk4`/`eb-cjson`
  already hit) - `HNodeReadAttrString`/`HNodeGetNextAttrName`/
  `HNodeInfoGetType` return a raw, freshly-heap-allocated `ANY PTR`
  instead (freed via `HFreeString`), matching `eb-cjson`'s own
  `JsonStringify`/`JsonFreeString` fix for exactly the same issue.
- No layout beyond `BGroupLayout` (see Status above).
- No drag-and-drop, clipboard, or menu (`BMenuBar`/`BMenuItem`) support.

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

A downstream program depending on this package via `ebpm` needs no
extra linker flags - `ebpm`'s own `.libs`-sidecar mechanism forwards
both `-l ebhaikushim` and `-l be` automatically (confirmed by building
a real consumer package with a plain `[dependencies] eb-haiku = ...`
entry - no manual `Lib`/`-l` configuration needed). To compile a
program directly with `ebc` instead (without going through `ebpm`),
link explicitly:

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
`scripts/haiku_verify.sh`. GUI behavior (Phase 2) has no automated
equivalent - there's no way to check "did it draw the right pixels" or
"did the window really appear" other than looking at it; each GUI
example/test in this package was verified by hand via Haiku's own
`screenshot -s` utility during development (see `examples/`'s own
window/button/drawing/layout examples for what was actually checked).

## Using as a dependency

```toml
[dependencies]
eb-haiku = "^0.2"
```

```basic
#include "eb-haiku.iface.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    PRINT "got a message"
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.YourName-YourApp")

DIM w AS HWindow
w = HWindowCreate(100, 100, 400, 300, "Hello from eBasic", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)
CALL HWindowShow(w)

CALL HApplicationRun(app)   ' blocks until the window closes - see Threading above
CALL HApplicationFree(app)
```

## Layout

- `native/` - the hand-written C++ shim (see above); its own standalone
  `CMakeLists.txt`, not driven by `ebpm`.
- `src/raw/` - the raw FFI layer.
- `src/*.bas` (excluding `raw/`) - the idiomatic layer; `src/lib.bas` is
  the package's `#include` aggregator (its own `[lib]` entry point).
- `examples/` - one small, focused example per Kit/GUI area, each run
  for real on Haiku hardware (screenshotted where visual).
- `tests/integration.bas` - a comprehensive Phase 1 test against real
  filesystem/attribute/message state; `tests/*_basics.bas` - one
  focused Phase 2 test per GUI area, each verified by hand (see
  Verifying above). Run via `scripts/haiku_verify.sh`, not `ebpm test` -
  a real, shown `BWindow` needs a live desktop session, not a plain
  headless "build and run" check.
