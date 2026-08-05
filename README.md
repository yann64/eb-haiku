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
  `BNodeInfo::GetType`/`SetType` from Phase 1 - bound as of v0.9.0, see
  below), `BAppFileInfo` (executable metadata - bound as of v0.9.0, see
  below) / `BResources` (embedded resources - still no current eBasic
  packaging story), the Disk Device Kit (mount/unmount, raw
  device path - a different Kit - bound as of v0.10.0, see below),
  `BQuery`'s `Push*`/`PushOp` stack
  builder (a string predicate covers the same expressiveness),
  live/watching variants (`BQuery::SetTarget`/`IsLive`,
  `BVolumeRoster::StartWatching`/`StopWatching` - both need
  `BMessenger`/message-loop integration, deferred together), typed
  attributes beyond the practical scalar set (`B_MESSAGE_TYPE`/
  `B_RECT_TYPE`/`B_POINT_TYPE`/`B_RGB_COLOR_TYPE` - the raw escape
  hatch already covers these), and `BVolume::GetIcon`/`SetName` (bound
  as of v0.11.0, see below).

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
beyond the specific set above (e.g. `AttachedToWindow`), and menus
(`BMenuBar`/`BMenuItem`). (Drag-and-drop, via `BView::DragMessage`, is
bound as of v0.9.0 - see below.)

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
  formats), styled-text translation (`BTextView` is bound as of v0.8.0,
  but only its plain-text API - `text_run_array` styled-text support is
  a separate, still-unbound gap), and per-translator configuration UI.
  (`BMemoryIO`/`BMallocIO` - in-memory, non-file-backed translation I/O -
  bound as of v0.11.0, see below.)

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
(`BPopUpMenu`/`BMenuField` are bound as of v0.8.0, radio-mode item
grouping as of v0.9.0 - see below.)

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
(`GetAppInfo`/`GetRunningAppInfo`/`FindApp`/`GetRecentDocuments`/
`Folders`/`Apps` and `BClipboard::StartWatching` are bound as of
v0.8.0; `BRoster::StartWatching` app launch/quit notifications and the
`entry_ref`-based `IsRunning`/`TeamFor`/`GetAppInfo`/`FindApp` overloads
are bound as of v0.9.0 - see below.)

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
**not a safely bindable target**, deliberately not attempted.
(`BSecureSocket`/TLS and `BDatagramSocket`/UDP are bound as of v0.8.0;
`BNetworkInterface`/`BNetworkRoster` - enumerating the *local*
machine's own interfaces - as of v0.9.0, see below.)

**Locale Kit (v0.7.0, complete)** - see `src/locale.bas`: locale-aware
formatting and comparison, ICU-backed, living directly in `libbe.so`
(no new link dependency) - `HDateFormat`/`HTimeFormat` (`Format` into a
plain `char*`/`maxSize` buffer, no `BString` involved at all),
`HNumberFormat` (`FormatDouble`/`FormatInt32`/`FormatMonetary`/
`FormatPercent`), `HCollator` (`Compare`/locale-aware string sorting -
a real gap eBasic's own comparison operators don't fill). **Not
bound**: per-locale customization beyond `BLocale::Default()`.
(`BCatalog` and the `Parse` methods - the inverse of `Format` - are
bound as of v0.11.0, see below.)

**Kernel Kit concurrency (v0.7.0, complete)** - see `src/thread.bas`:
real preemptive threads/semaphores/ports/shared-memory areas, bound
directly under `Lib "root"` (plain `extern "C"` functions, like
`find_directory`/`fs_create_index` - no shim needed at all).
`HSpawnThread`/`ResumeThread`/`WaitForThread`/`KillThread`/`Snooze`,
`HSemaphoreCreate`/`Acquire`/`Release`/`Delete`, `HPortCreate`/`Write`/
`Read`/`Delete`, `HAreaCreate`/`Delete`. Verified with real concurrency
correctness (a semaphore genuinely blocking a second thread until
released, a port read genuinely blocking until a writer thread sends -
`tests/thread_basics.bas`), not just "the calls don't crash." A
different kind of addition than the rest of this package - real,
language-level concurrency, not an "OS Kit" wrapper. (The `_etc`
timeout/flag variants and `clone_area`/`resize_area`/`find_area`/
`area_for` are bound as of v0.8.0 - see below.)

**Device Kit basics (v0.7.0, complete)** - see `src/serial.bas`:
`BSerialPort` - `HSerialPortOpen`/`Read`/`Write`/`SetBlocking`/
`SetTimeout`, real configuration (`SetDataRate`/`SetDataBits`/
`SetStopBits`/`SetParityMode` - **real enum values are small sequential
indices, NOT the literal baud rate etc.**, e.g. `H_9600_BPS` is `13`,
confirmed via a compiled probe, not assumed), enumeration
(`CountDevices`/`GetDeviceName`). **A real, confirmed detail**:
`HSerialPortOpen` returns a non-negative value (not necessarily `0`) on
success - check `>= 0`, unlike almost every other status-code-returning
function in this package. (Modem control lines - `SetDTR`/`SetRTS`/
`IsCTS`/etc. - and `SetFlowControl` are bound as of v0.8.0, see below;
likely no-ops/false on a virtual serial port with no real modem lines
wired up.)

**Package Kit basics (v0.7.0, complete)** - see `src/package.bas`:
`BPackageRoster` - `HPackageRosterIsRebootNeeded`, real repository
cache/config paths (reusing the existing `HPath` type directly), and
`HPackageRosterGetActivePackages` + `HPackageInfoSet`/`Iterator` to
list real installed packages by name/version (confirmed against 726
real packages on the development host, including `haiku` itself). **Not
bound**: the full `Solver`/`.hpkg` install/write machinery
(package-manager-authoring territory). (`VisitCommonRepositoryConfigs`/
`StartWatching` are bound as of v0.11.0, see below.)

**Media Kit basics (v0.7.0, complete) - a real, important deviation
from this package's own original plan** - see `src/media.bas`: real
Haiku's plain free-function `play_sound`/`stop_sound`/`wait_for_sound`
API (`media/PlaySound.h`) - originally intended as the simplest
possible path - is a **literal `UNIMPLEMENTED` stub** on real Haiku,
confirmed by direct reproduction (it logs `UNIMPLEMENTED` and does
nothing). This package binds the real, fully functional path instead:
`HSoundCreate` (loads a whole file via `BSound(entry_ref*)`) +
`HSoundPlayerCreate`/`Start`/`StartPlaying`/`IsPlaying`/`Stop` (a real
`BSoundPlayer`), verified via real wall-clock playback (confirmed audio
duration/timing against a real WAV file, not a mock). **Not bound**:
`BSound`-adjacent classes beyond loading a whole file - suited to a
native multimedia app, not "play this sound file" scripting glue.
(Real-time buffer-callback synthesis, `BufferPlayerFunc`, is bound as
of v0.11.0, see below.)

**`BPrintJob` (v0.7.0, complete - Interface Kit addition, not a new
Kit)** - see `src/printjob.bas`: real printing via a `ShimPrintJob`
subclass forwarding the virtual `DrawView()` to an eBasic callback,
which draws using this package's own already-bound view-drawing
primitives (`HViewSetHighColor`/`FillRect`/`DrawString`/`DrawBitmap`) -
a real, satisfying close of the loop between Interface Kit's two
previously-separate parts. `HPrintJobBeginJob`/`CommitJob`/`SpoolPage`/
`CanContinue`/`CancelJob`, `PaperRect`/`PrintableRect`/`GetResolution`
(`BRect`/plain ints, no new handle type). (`Settings`/`SetSettings`/
`IsSettingsMessageValid` are bound as of v0.8.0 - see below.)

**v0.8.0 (closing gaps in already-bound Kits)**: asked for a plan to
implement the Kits that aren't *fully* implemented (as opposed to
brand-new Kits) - research re-read every "not bound"/"out of scope"
list in this file, confirmed real APIs on the host, and surfaced seven
tractable candidates across two multi-select questions; user picked
all seven. No new libraries needed - everything here lives in
`libbe.so`/`libbnetapi.so`/`libroot.so`/`libdevice.so`, all already
linked.

- **Small polish bucket** - Kernel Kit `_etc` timeout/flag variants
  (`HSemaphoreAcquireEtc`/`ReleaseEtc`, `HPortReadEtc`/`WriteEtc`,
  `HWaitForThreadEtc`) and area introspection (`HAreaClone`/`Resize`/
  `Find`/`For`, `src/thread.bas`); `BSerialPort` modem control lines
  (`HSerialPortSetDTR`/`SetRTS`/`IsCTS`/`IsDSR`/`IsRI`/`IsDCD`/
  `SetFlowControl`, `src/serial.bas` - real, hardware-dependent, no-ops
  on this host's virtual serial port); `BPrintJob` `Settings`/
  `SetSettings`/`IsSettingsMessageValid` (`src/printjob.bas`, reusing
  the existing `HMessage` type). **Two real findings along the way**:
  `HAreaCreate`'s original `BYREF ANY PTR` parameter shape (shipped in
  v0.7.0) never actually compiled at any real call site - a real eBasic
  codegen issue with `BYREF ANY PTR` params, confirmed by direct
  reproduction (it had never actually been exercised by any test) -
  fixed by switching to the same `BYVAL`-pointer-to-pointer buffer-out
  convention used everywhere else in this package (a breaking but
  necessary signature fix, since no working caller could have existed
  before). And `HPrintJobSetSettings` can hang indefinitely with
  anything but a message from a real, configured job - the same
  interactive-dialog-hazard category as `ConfigJob`/`ConfigPage`.
- **`BTextView`** (`src/textview.bas`) - real multi-line, plain-text
  editing. Needs no shim subclass, unlike `BWindow`/`BView`: `Text()`
  returns a plain `const char*`, marshaling exactly like
  `HStringViewGetText`/`HTextControlGetText` already do.
  `HTextViewCreate`/`SetText`/`GetText`/`TextLength`/`SetWordWrap`/
  `MakeEditable`/`Select`. Styled text deliberately still out of scope.
- **`BPopUpMenu`/`BMenuField`** (`src/menu.bas`, extended) -
  `BPopUpMenu` IS-A `BMenu` (like `BMenuBar` already is) and reuses the
  existing `HMenu` type/`HMenuAddItem`/etc. directly; `HPopUpMenuGo`'s
  `async` parameter is the only headlessly-testable path (real item
  *selection* needs a human mouse click, the same real limitation as
  `HPrintJobConfigJob`). `HMenuFieldCreate`/`HMenuFieldMenu` wrap an
  existing `BMenu` in a labeled, clickable field.
- **`BMimeType`** (`src/mimetype.bas`) - the separate meta-mime
  database (distinct from the per-file `BNodeInfo` type from Phase 1):
  `HMimeTypeSetTo`/`InitCheck`/`IsValid`/`IsInstalled`/`Install`/
  `Delete`/`Type`, short/long description, preferred app, file
  extensions/supporting apps (via `HMessage`), static
  `GetInstalledTypes`/`GetInstalledSupertypes`, `GuessMimeType`. New
  generic `HMessageCountItems`/`FindStringAt` (`src/message.bas`) read
  `BMessage`'s own repeated-value fields. **A real, confirmed API
  inconsistency**: `GetInstalledSupertypes` fills a field named
  `"super_types"`, NOT `"types"` like `GetInstalledTypes` - easy to
  assume wrong, confirmed via probe before trusting it. Icon get/set
  bound as of v0.9.0, sniffer-rule get/set/check as of v0.11.0 (see
  below).
- **`HWatcher` + real live `BQuery`/`BVolumeRoster` watching** - the
  one genuinely new piece of infrastructure this phase: a small
  `ShimHandler : public BHandler` (`native/shim.cpp`, alongside
  `BLocker`/`BRoster`/`BClipboard`), `AddHandler`'d onto `be_app`,
  becomes a live `BMessenger` target for `HQuerySetTarget`
  (`src/query.bas`) and `HVolumeRosterStartWatching`/`StopWatching`
  (`src/volume.bas`, extended). **Three real findings, each confirmed
  via direct reproduction before trusting them**: (1)
  `HQuerySetTarget` alone does NOT establish the real live monitor,
  even though `HQueryIsLive` reports true immediately - `HQueryFetch`
  must still be called afterward, which is what actually registers the
  live watch with the kernel; (2) `HApplicationQuit` had a real,
  previously-undiscovered bug (never exercised cross-thread before this
  phase) - calling `Quit()` directly from a thread other than the one
  that called `Run()` fails ("you must Lock the application object") -
  fixed the same way `HWindowClose` already does, posting a real
  `B_QUIT_REQUESTED` message instead; (3) freeing a live query's
  watcher *after* freeing the owning `HApplication` is a real
  use-after-free (`HWatcherFree` does `be_app->RemoveHandler`
  internally) - the correct order (watcher/query before
  `HApplicationFree`) is now documented on `HWatcherFree` itself.
  Verified with real concurrency correctness: a background thread
  creates a file matching a live query's predicate, confirming a real
  `B_QUERY_UPDATE` genuinely arrives.
- **`BRoster` app-info/recent-lists + `BClipboard` watching**
  (`src/roster.bas`/`clipboard.bas`, extended) - `HRosterGetAppInfo`
  (by signature)/`GetRunningAppInfo` (by team)/`FindApp` (by MIME type)
  fill the existing `HPath` type from `app_info`'s own `entry_ref`,
  matching the `BPackageRoster` repository-path precedent.
  `HRosterGetRecentDocuments`/`Folders`/`Apps` via a new
  `HMessageFindRefAt` (`src/message.bas`, fills an `HPath`) reading a
  real repeated `entry_ref` field. `HClipboardStartWatching`/
  `StopWatching` via `HWatcher`. Verified against real system state:
  `GetAppInfo` against Tracker, `FindApp("text/plain")` correctly
  resolving to `StyledEdit`, and a real self-triggered clipboard-watch
  test confirming `B_CLIPBOARD_CHANGED` actually fires.
- **`BSecureSocket`/TLS + `BDatagramSocket`/UDP** (`src/network.bas`,
  extended) - `BSecureSocket` IS-A `BSocket`, so a single new
  `HSecureSocketCreate` (returning the existing `HSocket` type) is all
  that's needed - every other `HSocket*` function already dispatches
  correctly to the real TLS implementation via ordinary C++ virtual
  dispatch. `HDatagramSocket` (`Create`/`Bind`/`SendTo`/`ReceiveFrom`/
  `Free`) reuses the existing `HNetworkAddress` type. **A real,
  confirmed finding**: a freshly-created `HDatagramSocket` has no real
  underlying file descriptor until `HDatagramSocketBind` is called
  (created lazily by `Bind`/`Connect`, not the constructor) -
  `HDatagramSocketSendTo` on an unbound socket fails with a real "Bad
  file descriptor" status, even for the sender, which must bind to an
  ephemeral local address/port before ever sending. Verified with a
  real TLS handshake against a real HTTPS server (a manual `GET`
  request over the encrypted channel to `example.com`) and a real UDP
  loopback round-trip using a second thread as the receiver.

Verified end-to-end on real Haiku hardware via `eb-haiku`'s own
`scripts/haiku_verify.sh`, now running 34 `tests/*.bas` files. Five new
examples (`popup_menu.bas`, `text_editor.bas`, `mime_lookup.bas`,
`live_query.bas`, `https_fetch.bas`), one per major area. Published:
pushed with a `v0.8.0` tag, `ebpm-index` updated, `ebpm add eb-haiku`
confirmed resolving to `v0.8.0` from the live index.

**v0.9.0 (remaining gaps in already-bound Kits)**: asked again whether
any Kits are still not fully implemented - re-read every "not bound"/
"deliberately out of scope" line in this file, confirmed real APIs on
the host, and surfaced seven tractable candidates across two multi-
select questions; user picked all seven. No new libraries needed -
`BNetworkInterface`/`BNetworkRoster` live in the already-linked
`libbnetapi.so`; everything else lives in the already-linked
`libbe.so`.

- **Radio-mode menu grouping** (`src/menu.bas`, extended) -
  `BMenu::SetRadioMode`/`IsRadioMode`/`SetLabelFromMarked` - once radio
  mode is on, marking one item automatically unmarks its siblings,
  entirely handled internally by real Haiku. **A real, confirmed
  gotcha, a variant of the existing "needs BApplication first" family**:
  constructing a *new* `BMenu`/`BMenuItem` (or presumably any other
  `BView`) *after* the owning `HApplication` has already been freed
  hangs indefinitely - needs a still-*live* `BApplication`, not merely
  one that existed once.
- **`BMimeType` icon get/set** (`src/mimetype.bas`, extended) -
  `GetIcon`/`SetIcon` and the `*ForType` static-equivalent siblings,
  reusing the existing `HBitmap` type directly (`H_LARGE_ICON = 32`/
  `H_MINI_ICON = 16`, plain pixel dimensions). **Confirmed by direct
  reproduction, caught by a probe before shipping this time**: these
  hang indefinitely without a real `HApplication` existing first - the
  same family as `GetBitmap`/`BClipboard::Lock`.
- **`BAppFileInfo`** (new `src/appfileinfo.bas`) - real executable
  metadata: `SetTo`/`Get`/`SetSignature`, `Get`/`SetAppFlags`/
  `RemoveAppFlags`, `Get`/`SetSupportedTypes`/`IsSupportedType` (a
  `BMessage` repeated-string field, reusing `HMessageCountItems`/
  `FindStringAt` from v0.8.0). **A second real occurrence of the
  Translation Kit's own MI-pointer-adjustment bug class**:
  `eb_haiku_file_create` stores its handle as `BPositionIO*` (`BFile`'s
  non-first base, a non-zero-offset erasure), so a naive
  `static_cast<BFile*>` in the new `SetTo` shim function silently
  returned `B_BAD_VALUE` against a perfectly valid file - fixed via
  `dynamic_cast<BFile*>(static_cast<BPositionIO*>(handle))`, the same
  pattern the original bug was fixed with. The general lesson: any
  later, independently-written shim function receiving an
  already-erased handle from an earlier one must re-derive that exact
  erasure convention, not assume a plain `static_cast`.
- **Drag-and-drop** (`src/view.bas`/`message.bas`, extended) - the
  single most-requested standing gap, closed with the smallest useful
  slice: `HViewDragMessage` (`BView::DragMessage`, the simplest
  no-bitmap overload, called from inside an existing `MouseDown`
  callback) and `HMessageWasDropped`/`DropPoint` on the drop target's
  own existing `MessageReceived` callback. **Confirmed by direct
  reproduction**: calling `HViewDragMessage` outside a real `MouseDown`
  (i.e. without an actual mouse button currently held) blocks
  indefinitely - the same "not triggerable over SSH" limitation as
  `HPopUpMenuGo`/`HPrintJobConfigJob`; this package's own automated
  test never calls it, only `examples/drag_and_drop.bas`, meant to be
  run interactively.
- **`BTextView` styled text (color only)** (`src/textview.bas`,
  extended) - `SetFontAndColor`, scoped to `HTextViewSetStylable`/
  `IsStylable` + `HTextViewSetColor`/`GetColor` (a plain `rgb_color`
  value, no new handle type, no `BFont` binding needed). **A real,
  non-obvious finding, found only because the test checked an
  out-of-range offset**: real `BTextView::IsStylable()` defaults to
  `false`, and while false, `SetFontAndColor`'s own color change is NOT
  scoped to its given range at all - it silently applies to the ENTIRE
  text. `HTextViewSetStylable(tv, 1)` must be called first.
- **`BRoster::StartWatching` + `entry_ref` overloads** (`src/roster.bas`,
  extended) - real app launch/quit notifications
  (`HRosterStartWatching`/`StopWatching`, reusing the existing
  `HWatcher` primitive from v0.8.0; real `H_SOME_APP_LAUNCHED =
  1112686931`/`H_SOME_APP_QUIT = 1112686929`, confirmed via probe, not
  hand-derived) plus `IsRunningForPath`/`TeamForPath`/
  `GetAppInfoForPath`/`FindAppForPath` (a plain file path at this
  package's own idiomatic layer, constructing the real `entry_ref`
  internally via `BEntry`). **A real finding that took three iterative
  probes to pin down**: these notifications are only actually delivered
  while the watching program's own message loop (`Run()`) is actively
  pumping - triggering the launch/quit via a backgrounded `system()`
  shell subprocess produced zero notifications (an unrelated SSH-pipe-
  holding artifact from the backgrounded process keeping stdout open),
  and calling `Launch()` before `Run()` also produced zero notifications
  despite succeeding, because nothing was dispatching the already-queued
  messages yet - fixed by triggering from a background thread while
  `Run()` is already pumping on the main thread, the same pattern
  already proven for `BQuery`/`BVolumeRoster` watching in v0.8.0.
- **`BNetworkInterface`/`BNetworkRoster`** (new
  `src/networkinterface.bas`) - enumerates the local machine's own real
  network interfaces: `BNetworkRoster::Default()` (a shared,
  never-destroyed singleton, matching `be_roster`/`be_clipboard`'s own
  convention), `CountInterfaces`/`GetNextInterface`, and per-interface
  `Name`/`Flags`/`HasLink`/`CountAddresses`/`GetAddressAt`. An
  interface address's own `Address()` is copied into an existing
  `HNetworkAddress` (`network.bas`) rather than exposing a third
  address-shaped handle. Diagnostics/enumeration only in this phase -
  interface configuration is bound as of v0.11.0, see below.

Verified end-to-end on real Haiku hardware via `scripts/haiku_verify.sh`,
now running 38 `tests/*.bas` files. Five new examples
(`drag_and_drop.bas`, `styled_text.bas`, `mimetype_icon.bas`,
`app_launch_watching.bas`, `network_interfaces.bas`), one per major
area. Published: pushed with a `v0.9.0` tag, `ebpm-index` updated,
`ebpm add eb-haiku` confirmed resolving to `v0.9.0` from the live
index.

**v0.10.0 (five entirely new Kits)**: asked once more whether every
Kit is fully implemented - this time research went beyond the
already-bound Kits' own residual gaps and surveyed the real Haiku host
for Kits never touched at all. Six real, linkable candidates were
found (Mail, MIDI Kit 2, Game, OpenGL, Screen Saver, Bluetooth, Disk
Device); user picked all but Bluetooth Kit (real but lowest-confidence:
2007-origin headers, a differently-namespaced `Bluetooth::` convention
unlike every `B`-prefixed class elsewhere). Deep research then found
Screen Saver Kit is **not realistically bindable**: `BScreenSaver` only
works as a loadable `.so` add-on exporting `extern "C"
instantiate_screen_saver()`, which Haiku's screensaver daemon `dlopen`s
at runtime - but `ebc` has no shared-library/PIC output mode at all
(only a native executable or a static `.a` archive) - a compiler-level
limitation, documented in "Known gaps" below rather than attempted.

- **Mail Kit** (new `src/mail.bas`) - `BEmailMessage` (`SetTo`/
  `SetFrom`/`SetSubject`/`SetBodyTextTo`/`Attach`/`Send`) and
  `BMailDaemon` (`CheckMail`/`SendQueuedMail`/`CountNewMessages`/
  `MarkAsRead`/`Quit`/`Launch`). Plain `new`/`delete` throughout - no
  ref-counting. **Two real findings**: on a host with no mail account
  configured and no `mail_daemon` running, `CheckMail`/
  `CountNewMessages` return a real `B_MAIL_NO_DAEMON` status promptly
  (no hang) and `Send` fails - expected, documented behavior for that
  environment; and `IsComponentAttachment` (and the underlying
  `BMailComponent::IsAttachment`) return false even for a genuine
  attachment, despite `ComponentType()` correctly reporting
  `B_MAIL_ATTRIBUTED_ATTACHMENT` for that same component - a real,
  confirmed Mail Kit inconsistency, worked around by verifying via
  `CountComponents()` instead.
- **Game Kit** (new `src/game.bas`) - `BGameSound` and its three leaf
  subclasses: `BFileGameSound` (play a whole file), `BSimpleGameSound`
  (one-shot, file or raw in-memory PCM), `BPushGameSound` (direct
  lock/unlock buffer-fill polling, for procedurally-generated audio -
  no callback needed). Plain `new`/`delete` throughout, confirmed via
  probe to need no `BApplication` first either (a real, confirmed
  contrast with Media Kit's own `BSoundPlayer`). Every constructor
  returns the single shared `HGameSound` type directly (every leaf
  class IS-A `BGameSound`), matching this package's established
  base-type-reuse convention (e.g. `HPopUpMenuCreate` returning `HMenu`
  directly). Hit the same real eBasic codegen limitation already known
  from `HAreaCreate` (v0.8.0): a `BYREF ... AS ANY PTR` parameter shape
  doesn't compile at any real call site - fixed the same established
  way (`BYVAL ... AS ANY PTR` with the caller passing `@variable`
  explicitly).
- **OpenGL Kit** (new `src/glview.bas`) - `BGLView` (a real `BView`
  subclass, addable to a window exactly like any other view) via a new
  `ShimGLView` subclass overriding `Draw(BRect)` - directly reuses the
  existing `EbHaikuDrawCallback` typedef and forwarding pattern from
  `ShimView`/`ShimWindow`. `LockGL`/`UnlockGL`/`SwapBuffers` exposed as
  plain functions. Raw OpenGL calls (`glClear`/`glViewport`/`glBegin`/
  etc.) are a separate `libGL.so` surface, not Haiku API - bound
  directly via a new `Extern "C" Lib "GL"` declare (`src/raw/
  haiku_gl.bas`), matching the direct-`Lib`-declare precedent already
  used for Kernel Kit's `Lib "root"`, rather than hand-wrapping every
  GL entry point in the shim. Verified with a real, genuinely rendered
  dark-blue-cleared window and an interpolated red/green/blue triangle,
  confirmed via `screenshot -s` - true OpenGL rendering through the
  Software Pipe/llvmpipe backend.
- **Disk Device Kit** (new `src/diskdevice.bas`) - `BDiskDeviceRoster`/
  `BDiskDevice`/`BPartition`. **A first for this project**: the real
  classes live under `headers/private/storage`, not the public `os/`
  tree every other binding has used - a deliberate, documented
  exception (confirmed live-compilable/linkable with extra `-I` flags;
  the symbols themselves are in the already-linked `libbe.so`).
  `BDiskDevice` IS-A `BPartition` (single inheritance, no
  pointer-adjustment concern), so the `BPartition`-level functions
  (`Mount`/`Unmount`/`Name`/`ContentType`/`Size`/`ChildAt`/etc.) are
  shared and work on either handle directly. **A real, confirmed
  hazard found and deliberately avoided**: `BDiskDeviceRoster`'s own
  `VisitEachMountablePartition` does not reliably scope its
  enumeration to a childless `device` filter - a standalone C++ probe
  showed it visiting every real partition on the entire host,
  including the live boot volumes, and never returning. Not bound at
  all - enumeration instead uses only `GetNextDevice`/`RewindDevices`
  (matching `BVolumeRoster::GetNextVolume`'s own fill-in-place
  convention) plus direct `ChildAt`/`CountChildren` navigation, both
  confirmed safe. `BPartition` itself has a private ctor/dtor in real
  Haiku - there is deliberately no "free" function for it. Verified
  entirely against a throwaway loopback file device (`dd` + `mkfs -t
  bfs`, registered via `RegisterFileDevice`) - real `Mount`/`Unmount`/
  `GetMountPoint`, never any physical/boot device. A brief settle delay
  after `Mount` was needed - real Haiku's own Disk Device Kit runs
  `Mount` asynchronously via a background job queue, and an immediate
  `Unmount` right after occasionally raced with `B_BUSY`.
- **MIDI Kit 2** (new `src/midi.bas`) - the most novel binding in this
  package: `BMidiRoster` is a pure static-method facade (private
  ctor/dtor, never instantiated). Every endpoint class
  (`BMidiEndpoint`/`BMidiProducer`/`BMidiConsumer`/
  `BMidiLocalProducer`/`BMidiLocalConsumer`) is real-refcounted (a
  genuine `fRefCount` field + `Acquire()`/`Release()`, private/
  protected destructors enforcing it at compile time) - there is
  deliberately no "destroy" function anywhere in this file; the shim
  calls `Release()`, never `delete`. `BMidiLocalProducer`
  (`SprayNoteOn`/`NoteOff`/`ControlChange`/`ProgramChange`) and
  `BMidiLocalConsumer` via a new `ShimMidiConsumer` subclass (the same
  virtual-forwarding pattern as `ShimWindow`/`ShimView`) receiving real
  incoming MIDI through those same four callbacks plus a raw `Data()`
  catch-all. **Two real findings, both confirmed via standalone C++
  probes**: (1) both endpoints must be `Register()`'d with the roster
  BEFORE `Connect()`/`Spray*` for any data to actually be delivered -
  `Connect` itself succeeds and `IsConnected` reports true even without
  registering first, but messages then silently never arrive (real
  MIDI Kit 2 routing always goes through the out-of-process
  `midi_server`, even for two purely local endpoints); (2) a genuine
  shim bug, not a Haiku surprise - `ShimMidiConsumer`'s own `Data()`
  override must call the real `BMidiLocalConsumer::Data()` base
  implementation, which is what actually parses the raw byte stream and
  dispatches to `NoteOn`/`NoteOff`/`ControlChange` internally -
  overriding it without forwarding silently broke every other callback
  in the class, caught by a shim-level probe that bypassed eBasic
  entirely to isolate the bug from the glue code. Verified with a real,
  self-contained loopback test - a local producer connected to a local
  consumer in the same process, confirming `NoteOn`/`NoteOff`/
  `ControlChange` all genuinely arrive with matching field values.

Verified end-to-end on real Haiku hardware via `scripts/haiku_verify.sh`,
now running 43 `tests/*.bas` files. Five new examples
(`send_email.bas`, `game_sound.bas`, `opengl_triangle.bas`,
`disk_devices.bas`, `midi_loopback.bas`), one per new Kit. A real edge
case found while writing the Disk Device Kit example: `BPartition::
Name`/`Type`/`ContentType` are real `NULL` (not empty-string) for an
unformatted/empty removable drive (e.g. a CD/DVD drive with no media
inserted) - passing a `NULL const char*` through as a `ZSTRING` broke
`PRINT`; fixed by returning `""` from the shim whenever the real API
returns `NULL`. Published: pushed with a `v0.10.0` tag, `ebpm-index`
updated, `ebpm add eb-haiku` confirmed resolving to `v0.10.0` from the
live index.

**v0.11.0 (eight residual gaps in already-bound Kits)**: asked once
more whether every Kit is fully implemented - this round closed the 8
real, tractable residual items still listed as "not bound" across
`BVolume`/`BMimeType`/Locale Kit/Translation Kit/Network Kit/Media
Kit/Package Kit, surfaced across four multi-select questions; user
picked all eight.

- **`BVolume::GetIcon`/`SetName`** (`src/volume.bas`, extended) -
  `GetIcon` reuses the existing `HBitmap` type (real `BVolume` has no
  `SetIcon` at all - `GetIcon` only); `SetName` is a real, functional
  rename, not a documented no-op. **A 4th confirmed occurrence of the
  "needs `BApplication` first" gotcha family**: `HVolumeGetIcon` hangs
  indefinitely without one, caught via probe before shipping. Verified
  `GetIcon` against the real boot volume (read-only, safe) and
  `SetName` against a throwaway loopback BFS volume, never the real
  boot volume's own name.
- **`BMimeType` sniffer rules** (`src/mimetype.bas`, extended) -
  `GetSnifferRule`/`SetSnifferRule` (real `BString`-based, copied into
  the caller's buffer) and the static `CheckSnifferRule` validator.
  Verified with a real, valid rule (`"1.0 [0:3] ('PNG')"`, confirmed
  plausible via probe) round-tripped on a throwaway type, and a real
  invalid rule correctly rejected with Haiku's own detailed
  parse-error message.
- **Locale Kit `Parse` methods** (`src/locale.bas`, extended) -
  `HDateFormatParse`/`HTimeFormatParse`/`HNumberFormatParse`, the
  inverse of the already-bound `Format` direction. `BDate`/`BTime`'s
  own plain `int32` fields are copied out directly rather than binding
  whole new handle types for them. **Resolved a real open question from
  planning**: `BTime`/`BDate` are declared inside `namespace BPrivate`
  purely as an internal-organization quirk inside the *public*
  `os/support/DateTime.h` header, which re-exports both via `using
  BPrivate::BTime;`/`using BPrivate::BDate;` at global scope - fully
  stable, ordinary public API despite the namespace name; no caution
  needed after all. Verified via real round-trips through this host's
  own French locale formatting (`"14/11/2023"`, `"12 345,678"`).
- **`BCatalog`** (new `src/catalog.bas`) - the runtime-facing surface
  only (`GetString`/`SetTo`/`InitCheck`/`CountItems`) - deliberately
  does not attempt `collectcatkeys`/`linkcatkeys` themselves (a
  separate, build-time tooling pipeline, not a runtime API). Real and
  useful even with zero `.catkeys` data installed: `GetString`
  gracefully echoes the key itself back unchanged when no catalog
  covers it - confirmed to be the entire point of the real
  `B_TRANSLATE` macro convention, verified exactly this way against a
  throwaway signature.
- **`BMemoryIO`/`BMallocIO`** (`src/file.bas`, extended) - both real
  `BPositionIO` subclasses (single inheritance, no pointer-adjustment
  concern), usable directly anywhere `HFile` already is.
  Verified with a real, entirely in-memory round trip: decode a real
  PNG, `Translate` it into a growing `BMallocIO`, then wrap that exact
  buffer read-only as a `BMemoryIO` and decode it back - no
  intermediate file on disk at all.
- **`BNetworkInterface` configuration** (`src/networkinterface.bas`,
  extended) - `SetFlags`/`SetMTU`/`SetMedia`/`SetMetric`, the simple
  `BNetworkAddress`-based overloads of `AddAddress`/`RemoveAddress`/
  `RemoveAddressAt`, `AddDefaultRoute`/`RemoveDefaultRoute`, and
  `AutoConfigure`. Deliberately does not bind the fuller
  `BNetworkInterfaceAddress`-based overloads or `AddRoute`/
  `RemoveRoute`'s own `BNetworkRoute`-based overloads (raw `sockaddr`
  manipulation) - disproportionate new surface/risk for this pass.
  **SAFETY-CRITICAL**: verified via a standalone C++ probe first, then
  only ever exercised against the real loopback interface - never the
  live NICs an active SSH session might depend on; loopback health and
  SSH connectivity explicitly re-confirmed after every test run.
- **Media Kit real-time buffer synthesis** (`src/media.bas`, extended)
  - a new `BSoundPlayer` constructor overload taking a real
  `BufferPlayerFunc` callback, its own `media_raw_audio_format`
  parameter unpacked into plain scalars at the shim's own trampoline.
  **A real, confirmed shim bug caught by a standalone C++ probe before
  shipping**: real `BSoundPlayer::Cookie()` returns a real, non-`NULL`
  internal pointer even for a plain `HSoundPlayerCreate` result (not
  `NULL`, as might be assumed) - a single shared destroy function that
  unconditionally called `delete Cookie()` corrupted the heap and hung
  the process the moment a plain player was destroyed. Fixed by giving
  the buffer-callback path its own dedicated free function, never
  shared with the plain one. Verified with a real, genuinely
  synthesized 440Hz tone (50 real callback invocations in 500ms).
- **Package Kit repo-config visiting/watching** (`src/package.bas`,
  extended) - `VisitCommonRepositoryConfigs`/`VisitUserRepositoryConfigs`
  via a new `ShimRepositoryConfigVisitor` subclass (the same
  virtual-forwarding pattern as `ShimWindow`/`ShimView` - real Haiku
  only ever calls a visitor as a functor, never a plain callback), and
  `StartWatching`/`StopWatching` reusing the existing `HWatcher`
  primitive. Verified `VisitCommonRepositoryConfigs` against this
  host's own two real repository config files (Haiku, HaikuPorts);
  `StartWatching`/`StopWatching` verified functionally (the calls
  themselves succeed) - a real package installation/removal event is
  deliberately not triggered, too invasive to force safely on a shared
  host.

Verified end-to-end on real Haiku hardware via `scripts/haiku_verify.sh`,
now running 48 `tests/*.bas` files. Eight new examples
(`volume_icon_and_rename.bas`, `mimetype_sniffer_rule.bas`,
`locale_parse.bas`, `catalog_lookup.bas`, `memory_translate.bas`,
`network_interface_configure.bas`, `synth_tone.bas`,
`package_repo_configs.bas`), one per area.

With v0.11.0 shipped, every candidate surfaced by two full survey
rounds (v0.10.0's new-Kit search and this version's own residual-gap
search) is now bound except Bluetooth Kit (not selected - real but
lowest-confidence) and Screen Saver Kit (confirmed not bindable given
`ebc`'s current lack of a shared-library output mode, see "Known
gaps"). Published: pushed with a `v0.11.0` tag, `ebpm-index` updated,
`ebpm add eb-haiku` confirmed resolving to `v0.11.0` from the live
index.

### Media Kit / `BPrintJob` - real background-thread and interactive-dialog gotchas

**A real, new category of gotcha, confirmed by direct reproduction**:
`HSoundPlayer`/`HSound` are opaque heap handles, not C++ RAII objects -
nothing destructs them automatically. `ExitProcess` (this project's own
core Process Library function) only calls `std::exit()`, which runs
static-storage-duration destructors but **not** a live thread's own
cleanup - if the process reaches `ExitProcess` (including on an error/
`FAIL` path, not just the success path) while an `HSoundPlayer` is still
active, its background thread (talking to `media_server`) can hang the
whole process instead of exiting. **Always call `HSoundPlayerStop` +
`HSoundPlayerFree` (and `HSoundRelease`) before the program exits by
any path** - see `media.bas`'s own doc comment and
`tests/media_basics.bas` for the pattern (every `FAIL` branch cleans up
first).

**Separately, confirmed by direct reproduction**: `HPrintJobConfigJob`/
`ConfigPage` show a real, interactive Page Setup/Print dialog and block
indefinitely waiting for a human to click through it - not triggerable
over SSH, the same real limitation already documented below for mouse
clicks. This package's own tests/examples deliberately never call
them headlessly; run `examples/print.bas` from a real Haiku desktop
session instead.

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
  `HClipboard`/`HSocket`/`HNetworkAddress`/`HUrl`/`HDateFormat`/
  `HTimeFormat`/`HNumberFormat`/`HCollator`/`HSerialPort`/
  `HPackageRoster`/`HPackageInfoSet`/`HPackageInfoIterator`/`HSound`/
  `HSoundPlayer`/`HPrintJob`/`HTextView`/`HMimeType`/`HWatcher`/
  `HDatagramSocket`/`HAppFileInfo`/`HNetworkInterface`/`HNetworkRoster`/
  `HEmailMessage`/`HMailDaemon`/`HGameSound`/`HGLView`/
  `HDiskDeviceRoster`/`HDiskDevice`/`HPartition`/`HMidiProducer`/
  `HMidiConsumer`/`HCatalog`/`HMemoryIO`/`HMallocIO`, each a thin
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
- **`ebpm`'s automatic linker-flag forwarding doesn't cover Translation
  Kit, Network Kit, Device Kit, Package Kit, Media Kit, Mail Kit, Game
  Kit, OpenGL Kit, or MIDI Kit 2 functions** - a downstream program
  calling any of these needs to pass `-l translation`/`-l bnetapi`/
  `-l device`/`-l package`/`-l media`/`-l mail`/`-l game`/`-l GL`/
  `-l midi2` itself; see this file's own "Building" section for why and
  the exact flags.
- **Screen Saver Kit is not bindable with `ebc` as it stands today** -
  `BScreenSaver` only works as a loadable `.so` add-on exporting
  `extern "C" instantiate_screen_saver()`, which Haiku's screensaver
  daemon `dlopen`s at runtime, but `ebc` has no shared-library/PIC
  output mode at all (only a native executable, or a static `.a` via
  `--lib`) - confirmed from `ebc`'s own docs, not assumed. Revisit only
  if `ebc` ever gains such a mode - a compiler-level feature, not a
  bindings task.

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
downstream program that calls **any Translation Kit, Network Kit,
Device Kit, Package Kit, Media Kit, Mail Kit, Game Kit, OpenGL Kit, or
MIDI Kit 2 function** needs to *also* pass `-l translation`/
`-l bnetapi`/`-l device`/`-l package`/`-l media`/`-l mail`/`-l game`/
`-l GL`/`-l midi2` itself - `ebpm`'s sidecar mechanism can't discover
these automatically, because they're transitive link dependencies of
the *compiled shim itself* (`shim_translation.cpp.o`/
`shim_network.cpp.o`/`shim_device.cpp.o`/`shim_package.cpp.o`/
`shim_media.cpp.o`/`shim_mail.cpp.o`/`shim_game.cpp.o`/`shim_gl.cpp.o`/
`shim_midi.cpp.o` inside `libebhaikushim.a`), not something any
`Extern "C" Lib` clause in this package's own `.bas` source captures -
and unlike `find_directory`/`fs_create_index`/the Kernel Kit
concurrency primitives, none of `libtranslation.so`/`libbnetapi.so`/
`libdevice.so`/`libpackage.so`/`libmedia.so`/`libmail.so`/`libgame.so`/
`libGL.so`/`libmidi2.so` export a single plain (non-C++-mangled) symbol
to hang the same fix on (confirmed via `nm -D --defined-only` on the
real host - only `_init`/`_fini`). Reproduced directly: a real
downstream package using only `[dependencies] eb-haiku = ...` and
calling `HTranslatorRosterDefault`/`HNetworkAddressSetTo` fails to link
with "undefined reference" errors from inside `libebhaikushim.a` until
`-l translation -l bnetapi` are added explicitly. Code that never
touches these Kits' own functions is unaffected (their own object
files inside the archive are never pulled into the link). Locale Kit,
Disk Device Kit, and the Kernel Kit concurrency primitives need no
extra *linker* flags at all - the former two live directly in
`libbe.so` (Disk Device Kit's real classes live under a private
*header* path, `headers/private/storage` - a build-time `-I` concern
only for compiling `libebhaikushim.a` itself, already handled by
`native/CMakeLists.txt`; downstream consumers never touch those headers
directly), and Kernel Kit concurrency is plain `Lib "root"` functions
like `find_directory`.

To compile a program directly with `ebc` (without going through
`ebpm`), link explicitly - include whichever of `-l translation
-l bnetapi -l device -l package -l media -l mail -l game -l GL
-l midi2` your own code actually touches:

```sh
ebc yourprogram.bas -o yourprogram -L /boot/system/non-packaged/develop/lib -l ebhaikushim -l be -l translation -l bnetapi -l device -l package -l media -l mail -l game -l GL -l midi2 -l root
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
layout area). `BPrintJob`'s own `ConfigJob`/`ConfigPage` show a real,
interactive dialog with the same limitation (see this file's own Media
Kit/`BPrintJob` gotcha section above) - `tests/printjob_basics.bas`
deliberately never calls them, verifying everything else headlessly
instead.

## Using as a dependency

```toml
[dependencies]
eb-haiku = "^0.11"
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
