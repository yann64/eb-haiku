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

**Storage Kit extensions (v0.5.0, complete)** - see `src/entry.bas`/
`node.bas` (extended), `src/symlink.bas`, `src/volume.bas`,
`src/query.bas`:

- **`BStatable`** (permissions/owner/group/size/modification+creation
  time, `IsSymLink`, `GetVolume`) on `HEntry`/`HNode` - bound **per
  concrete type** (not one generic `BStatable*`-accepting function),
  each shim function `static_cast`-ing its own handle straight to its
  own known concrete type - a real lesson from the Translation Kit's
  `BFile` multiple-inheritance bug (see below): a `void*` handle can
  only safely become a base-class pointer at a point where the
  compiler still knows its real static type.
- **`BNode` typed attributes** beyond the existing string pair -
  `HNodeWriteAttrInt32`/`Int64`/`Bool`/`Double` + matching `Read*`
  (found/not-found, not just a bare sentinel), a raw `B_RAW_TYPE`
  escape hatch (`HNodeWriteAttrRaw`/`ReadAttrRaw`) for anything else,
  and `HNodeGetAttrInfo` to introspect an unknown attribute's real
  type/size (e.g. one written by another real Haiku app) before
  reading it.
- **`BSymLink`** (`HSymLinkCreate`/`ReadLink`/`IsAbsolute`) +
  `HDirectoryCreateSymLink` - real symlinks, a real POSIX-ish feature
  Haiku fully supports.
- **`BVolume`/`BVolumeRoster`** (`HVolumeRosterGetNextVolume`/
  `GetBootVolume`, `HVolumeCapacity`/`FreeBytes`/`GetName`/
  `IsReadOnly`/... ) - real mounted-volume/disk info.
- **`BQuery`** (`HQueryCreate`/`SetVolume`/`SetPredicate`/`Fetch`/
  `GetNextEntry`) - Haiku's own live, attribute-based filesystem search,
  with no POSIX equivalent, bound via the plain predicate-string API
  (`SetPredicate`) rather than the `Push*`/`PushOp` reverse-polish
  stack builder (identical expressiveness for one string parameter).
  **A real, sharp BFS behavior, confirmed by direct reproduction**: a
  query predicate only ever matches *indexed* attributes, and indexing
  is **not retroactive** - an attribute value written *before* its
  index existed is never picked up by that index, silently, no error
  anywhere. `HCreateIndex` (a real, plain `extern "C"` kernel function,
  `fs_create_index` - not a shim wrapper, like `find_directory`) must
  run *before* the attribute is ever written, not just before the
  query - see `HCreateIndex`'s own doc comment in `src/query.bas` and
  `examples/query_files.bas`.
- **Explicitly out of scope, with reasoning**: `BMimeType` (the
  separate meta-mime-database class - icons, sniffer rules, supported-
  apps registry; the common per-file case is already covered by
  `BNodeInfo::GetType`/`SetType` from Phase 1), `BAppFileInfo`/
  `BResources` (executable metadata/embedded resources - no current
  eBasic packaging story), the Disk Device Kit (mount/unmount, raw
  device path - a different Kit), `BQuery`'s `Push*`/`PushOp` stack
  builder (a string predicate covers the same expressiveness),
  live/watching variants (`BQuery::SetTarget`/`IsLive`,
  `BVolumeRoster::StartWatching`/`StopWatching` - both need
  `BMessenger`/message-loop integration, deferred together), typed
  attributes beyond the practical scalar set (`B_MESSAGE_TYPE`/
  `B_RECT_TYPE`/`B_POINT_TYPE`/`B_RGB_COLOR_TYPE` - the raw escape
  hatch already covers these), and `BVolume::GetIcon`/`SetName`.

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
a separate per-control one.

**Layout Kit (v0.3.0, complete)** - see `src/layout.bas`, `src/view.bas`:

- `BGroupLayout` (row/column), `BGridLayout` (rows+columns, with
  spanning/per-column-row weight and min/max width/height),
  `BCardLayout` (shows exactly one child at a time), `BSplitView`
  (resizable panes with a draggable splitter - a real `BView`, not a
  `BLayout`), `BSpaceLayoutItem` (glue/struts).
- Attachable at the **window or view level** (`HWindowSetLayout`/
  `HViewSetLayout`) - a layout can be nested inside an ordinary view,
  itself added to a parent layout, not only ever at the top.
- Per-view explicit size/alignment constraints
  (`HViewSetExplicitMinSize`/`MaxSize`/`PreferredSize`/`Size`/
  `Alignment`) - work on any view/control handle.
- `BGroupLayout`/`BGridLayout`/`BCardLayout` all share Haiku's own real
  `BLayout` base with a *virtual* `AddView`/`AddItem` - `HLayoutAddView`/
  `HLayoutAddItem` work uniformly on any of the three via ordinary C++
  virtual dispatch, no per-type duplication needed.
- **Not bound, deliberately** (not a gap - already fully covered):
  `BLayoutBuilder` (a pure templated C++ convenience API with no stable
  ABI - it only ever calls the same methods already bound directly) and
  `BGroupView`/`BGridView`/`BCardView` (convenience `BView`-with-
  built-in-layout subclasses - already achievable in two calls via
  `HViewCreate` + `HViewSetLayout`).

**Explicitly out of scope**: overriding `BView`/`BWindow` methods
beyond the specific set above (e.g. `AttachedToWindow`, drag-and-drop),
and menus (`BMenuBar`/`BMenuItem`).

**Translation Kit (v0.4.0, complete)** - see `src/translation.bas`,
`src/bitmap.bas`, `src/file.bas`: Haiku's own system for converting
between data formats, most commonly images (PNG/JPEG/BMP/GIF/TIFF/
WebP/...), backed by 20 real installed translator add-ons on a typical
Haiku system.

- `BFile` (minimal - just enough to drive Translation Kit's own I/O)
  and `BBitmap` (minimal - hold/inspect/draw a loaded image), the two
  necessary supporting bindings - not a general Storage Kit/Interface
  Kit expansion.
- `BTranslationUtils::GetBitmap` (`HGetBitmap`) - the single
  highest-value function: load any supported image format from an
  `HFile` stream directly into an `HBitmap`.
- `BTranslatorRoster` (`HTranslatorRosterDefault`/`HTranslate`/
  `HIdentify`/`HAddTranslators`, plus introspection -
  `HGetAllTranslators`/`HTranslatorInfo`/`HInputFormats`/
  `HOutputFormats`) and `BBitmapStream` (`HBitmapStreamCreate`/
  `HBitmapStreamDetachBitmap`) for the "save this bitmap as PNG/
  JPEG/..." direction.
- `HViewDrawBitmap` (`src/view.bas`) - draw a loaded `HBitmap` directly
  into a window, the natural pairing with the GUI Kit above.
- **A real, non-obvious limitation, confirmed by direct reproduction**:
  `HTranslate` going straight from one *compressed* format to a
  *different* compressed format in a single call typically fails with
  `B_NO_TRANSLATOR` - most translators only declare their own format
  and the generic uncompressed `H_TRANSLATOR_BITMAP` ("bits") as
  inputs, not other compressed formats directly. Convert in two hops
  instead: `HGetBitmap` the source, then `HBitmapStreamCreate` the
  result and `HTranslate` *that* to the real target format - see
  `examples/convert_image_format.bas` and `HTranslate`'s own doc
  comment in `src/translation.bas`.
- **Explicitly out of scope, with reasoning**: writing a custom
  `BTranslator` subclass (would need the same virtual-forwarding shim
  machinery as `ShimWindow`/`ShimView` for very little real value - the
  20 already-installed translators cover essentially all common real
  formats), styled-text translation (needs `BTextView`, an unbound
  multi-line control - a separate Interface Kit gap), per-translator
  configuration UI, and `BMemoryIO`/`BMallocIO` (in-memory, non-file-
  backed translation I/O - a reasonable future addition, not blocking).

### Translation Kit - read this before calling any Translation Kit function

`BTranslationUtils::GetBitmap` (and, by extension, the rest of the
Translation Kit - it goes through the same registrar/add-on system)
**hangs indefinitely** if called before any `HApplication` exists -
confirmed by direct reproduction in a standalone C++ program with no
eBasic involved at all. Always call `HApplicationCreate` first - not a
new burden for a real GUI/app program, which always needs one anyway,
but a real trap if you only want to use the Translation Kit on its own
(you do not need to call `HApplicationRun` - just constructing the
`HApplication` is enough).

**`BLocker` (v0.6.0, complete)** - see `src/locker.bas`: a real mutex/
locking primitive (`Lock`/`LockWithTimeout`/`Unlock`/`IsLocked`/
`CountLocks`, real recursive semantics). Closes the risk this README
used to document as unsolved in its own "Threading" section below.
**Not bound**: `BAutolock` - header-only inline RAII with no
out-of-line methods to wrap, and doesn't map onto eBasic's own scoping
model; use explicit `HLockerLock`/`HLockerUnlock` instead, the same
pattern every other handle in this package already uses.

**Menus (v0.6.0, complete)** - see `src/menu.bas`: real `BMenuBar`/
`BMenu`/`BMenuItem` (`HMenuBarCreate`/`HMenuCreate`/`HMenuItemCreate`/
`HMenuItemCreateSubmenu`, `HMenuAddItem`/`AddSubmenu`/
`AddSeparatorItem`, `HMenuItemSetEnabled`/`SetMarked`). **A real,
confirmed requirement**: a menu bar's own constructor takes no `BRect`
frame at all - it renders at zero size (invisible) unless hosted in a
real layout (`HWindowSetLayout` + `HGroupLayoutAddView` as the first
item), not a plain `HWindowAddChild` - see `HMenuBarCreate`'s own doc
comment. `HMenuItemInvokeViaMessenger` mirrors `HButtonInvoke`'s own
`Messenger()`-based fix (`BMenuItem` is a `BInvoker` too - same crash
risk) - confirmed the real auto-target-to-window behavior end to end
with it (`tests/menu_basics.bas`), with no real mouse hardware needed.
**Not bound**: `BPopUpMenu` (context menus - different usage pattern),
`BMenuField` (a separate, combined menu+text-field control), radio-mode
item grouping.

**`BRoster`/`BClipboard` (v0.6.0, complete)** - see `src/roster.bas`,
`src/clipboard.bas`: find/launch/activate other running apps
(`HRosterIsRunning`/`TeamFor`/`Launch`/`ActivateApp`/`Broadcast`) and
system copy/paste (`HClipboardLock`/`Clear`/`Commit`/`Revert`/`Data`,
plus `HClipboardSetText`/`GetText` convenience wrappers). **A real,
confirmed text convention**: Haiku's own clipboard stores plain text as
a raw `B_MIME_TYPE` field named `"text/plain"` (confirmed via the real
`clipboard` command-line tool's own debug dump) - `HClipboardSetText`/
`GetText` already do this correctly; `HMessageAddData`/`FindData`
(`src/message.bas`) is the general escape hatch for other MIME types.
**Not bound**: `GetAppInfo`/`FindApp`/`GetRecentDocuments` (return
`app_info`/`entry_ref` structs - a much larger surface for
comparatively niche value), `BClipboard::StartWatching` (live
notification - continues the established "no live/watching APIs"
theme from `BQuery`/`BVolumeRoster`).

**Network Kit + `BUrl` (v0.6.0, complete)** - see `src/network.bas`:
real TCP networking - `BNetworkAddress` (`HNetworkAddressSetTo`, real
DNS resolution), `BSocket` (`HSocketConnect`/`Read`/`Write`/
`Disconnect`), and `BUrl` (Support Kit's own URL-parsing value class -
`HUrlCreate`/`Protocol`/`Host`/`Port`/`Path`/`IsValid`, no I/O of its
own). TCP only. **A real, confirmed finding**: Haiku's high-level HTTP/
URL-request API (`BUrlRequest`/`BHttpRequest`/`BUrlProtocolRoster`)
lives only under `headers/private/netservices{,2}/` - one class is
literally declared inside `namespace BPrivate::Network`, and the only
libs (`libnetservices.a`/`libnetservices2.a`) are static, unversioned
internals, not the stable `libbnetapi.so` this package links against -
**not a safely bindable target**, deliberately not attempted. **Not
bound**: `BSecureSocket`/TLS (real added complexity around certificate
handling - a good separate future phase), `BDatagramSocket`/UDP
(smallest-useful-slice-first - TCP covers the common case),
`BNetworkInterface`/`BNetworkRoster` (enumerating the *local* machine's
own interfaces - a diagnostics feature, not core to "connect to a
server").

### `BClipboard`/Translation Kit/`BRoster` - read this before calling any of them standalone

**A real, recurring gotcha, confirmed twice independently** (see
`BTranslationUtils::GetBitmap`'s own note above): `BClipboard::Lock()`
(and, by extension, the rest of `BClipboard`) also **hangs
indefinitely** if called before any `HApplication` exists - confirmed
by direct reproduction in a standalone C++ program with no eBasic
involved at all. Always call `HApplicationCreate` first (no need to
call `HApplicationRun`) - not a new burden for a real GUI/app program,
but a real trap if you only want to use the clipboard on its own (see
`examples/roster_and_clipboard.bas`).

### Threading - read this before writing a GUI program

`BApplication::Run()` blocks whichever thread calls it. Each `BWindow`,
once shown, runs its own message loop on its own separate thread - so
a program with even a single window already involves two threads, and
every window/view callback (`HWindowSetMessageReceivedCallback`,
`HShimViewSetDrawCallback`, etc.) is invoked from *that window's own
thread*, never the thread that called `HApplicationRun`.

**The safe, intended usage pattern**: the thread that calls
`HApplicationRun` does nothing else afterward - all real program logic
lives inside the window/app-level callbacks, which Haiku's own
per-window message queue already serializes one at a time. Multiple
simultaneous windows each get their own thread; if their callbacks ever
need to touch shared state, use a real `HLocker` (`BLocker` - see
`src/locker.bas`) around every access - confirmed via a real two-window
contention test (`tests/locker_basics.bas`) that this genuinely
prevents lost updates, not just "doesn't crash."

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
  `HGroupLayout`/`HGridLayout`/`HCardLayout`/`HSplitView`/`HBitmap`/
  `HFile`/`HTranslatorRoster`/`HBitmapStream`/`HSymLink`/`HVolume`/
  `HVolumeRoster`/`HQuery`/`HLocker`/`HMenu`/`HMenuItem`/`HRoster`/
  `HClipboard`/`HSocket`/`HNetworkAddress`/`HUrl`, each a thin
  `TYPE ... : handle AS ANY PTR : END TYPE` wrapper plus free functions.
  Every parameter is explicitly `BYVAL` - each is just an 8-byte handle,
  cheap to copy. `BSize`/`BAlignment` are likewise plain value structs
  in real Haiku (two `float`s / two `int`s) - passed as separate
  parameters throughout, exactly like `BRect`, never needing their own
  handle/`TYPE`.

## Known gaps

- **No top-level `STRING`-returning function can cross an `ebpm --lib`
  package boundary yet** (the same restriction `eb-gtk4`/`eb-cjson`
  already hit) - `HNodeReadAttrString`/`HNodeGetNextAttrName`/
  `HNodeInfoGetType` return a raw, freshly-heap-allocated `ANY PTR`
  instead (freed via `HFreeString`), matching `eb-cjson`'s own
  `JsonStringify`/`JsonFreeString` fix for exactly the same issue.
- No drag-and-drop support.
- **`ebpm`'s automatic linker-flag forwarding doesn't cover Translation
  Kit or Network Kit functions** - a downstream program calling either
  needs to pass `-l translation`/`-l bnetapi` itself; see this file's
  own "Building" section for why and the exact flags.

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
extra linker flags for Phase 1/Interface/Layout/Storage Kit
functionality - `ebpm`'s own `.libs`-sidecar mechanism forwards both
`-l ebhaikushim` and `-l be` automatically (it records every distinct
`Extern "C" Lib "name"` clause found anywhere in a package's own raw
layer - see `raw/haiku_find_directory.bas`'s/`raw/haiku_fs_index.bas`'s
own top comments for how `-l be`/`-l root` specifically got captured
this way, by binding a real plain C function directly under that `Lib`
name).

**A real, structural limitation, confirmed directly (not assumed)**: a
downstream program that calls **any Translation Kit or Network Kit
function** needs to *also* pass `-l translation`/`-l bnetapi` itself -
`ebpm`'s sidecar mechanism can't discover these automatically, because
they're transitive link dependencies of the *compiled shim itself*
(`shim_translation.cpp.o`/`shim_network.cpp.o` inside
`libebhaikushim.a`), not something any `Extern "C" Lib` clause in this
package's own `.bas` source captures - and unlike `find_directory`/
`fs_create_index`, neither `libtranslation.so` nor `libbnetapi.so`
exports a single plain (non-C++-mangled) symbol to hang the same fix
on (confirmed via `nm -D --defined-only` on the real host - only
`_init`/`_fini`). Reproduced directly: a real downstream package using
only `[dependencies] eb-haiku = ...` and calling
`HTranslatorRosterDefault`/`HNetworkAddressSetTo` fails to link with
"undefined reference" errors from inside `libebhaikushim.a` until
`-l translation -l bnetapi` are added explicitly. Code that never
touches Translation/Network Kit functions is unaffected (their own
object files inside the archive are never pulled into the link).

To compile a program directly with `ebc` (without going through
`ebpm`), link explicitly - include `-l translation -l bnetapi` too if
your own code touches either Kit:

```sh
ebc yourprogram.bas -o yourprogram -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be -l translation -l bnetapi -l root
```

## Verifying

```sh
scripts/haiku_verify.sh [ssh-host]   # default host: haiku
```

Builds the shim, runs `ebpm build`, then compiles and runs every
`tests/*.bas` file on the given SSH host - mirroring eBasic's own
`scripts/haiku_verify.sh`. GUI behavior (Phase 2/Layout Kit) and
`HViewDrawBitmap` (Translation Kit) have no automated visual
equivalent - there's no way to check "did it draw the right pixels" or
"did the grid/split/card layout actually look right" other than
looking at it; each GUI example/test in this package was verified by
hand via Haiku's own `screenshot -s` utility during development (see
`examples/` for what was actually checked - one example per Kit/GUI/
layout area).

## Using as a dependency

```toml
[dependencies]
eb-haiku = "^0.6"
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

## Repository layout

- `native/` - the hand-written C++ shim (see above); its own standalone
  `CMakeLists.txt`, not driven by `ebpm`.
- `src/raw/` - the raw FFI layer.
- `src/*.bas` (excluding `raw/`) - the idiomatic layer; `src/lib.bas` is
  the package's `#include` aggregator (its own `[lib]` entry point).
- `examples/` - one small, focused example per Kit/GUI/layout area,
  each run for real on Haiku hardware (screenshotted where visual).
- `tests/integration.bas` - a comprehensive Phase 1 test against real
  filesystem/attribute/message state; `tests/*_basics.bas` - one
  focused test per Phase 2/Layout Kit area, each verified by hand (see
  Verifying above). Run via `scripts/haiku_verify.sh`, not `ebpm test` -
  a real, shown `BWindow` needs a live desktop session, not a plain
  headless "build and run" check.
