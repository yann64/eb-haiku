' Idiomatic layer: BScreenSaver (via the native shim's own
' ShimScreenSaver - see native/shim_screensaver.cpp's own top comment
' for why a real C++ subclass is unavoidable here).
'
' Unlike every other Kit in this package, the whole program consuming
' this one is itself the real, dynamically loadable add-on Haiku's own
' screensaver daemon `dlopen`s - built via `ebc --shared-lib`/`-dll`,
' with a bodied `Extern "C" Function instantiate_screen_saver(archive AS
' ANY PTR, id AS INTEGER) AS ANY PTR` as the real, unmangled entry point
' the daemon `dlsym`s. See tests/screensaver_basics.bas and
' examples/screensaver_example.bas for the full real shape.
'
' `archive` (an opaque BMessage* forwarded straight through as ANY PTR)
' is directly usable with this package's own existing HMessage-family
' getters (message.bas) if a screensaver wants to read its own prior
' saved settings - no new binding work needed for that.

#include once "raw/haiku_shim_screensaver.bas"

TYPE HScreenSaver
    handle AS ANY PTR
END TYPE

''' `archive`/`id` are the exact same values `instantiate_screen_saver`
''' itself received from the daemon - forward them straight through.
FUNCTION HScreenSaverCreate(archive AS ANY PTR, BYVAL id AS INTEGER) AS HScreenSaver
    DIM s AS HScreenSaver
    s.handle = eb_haiku_screensaver_create(archive, id)
    HScreenSaverCreate = s
END FUNCTION

''' `cb` must be a plain top-level bodied FUNCTION taking (userData AS
''' ANY PTR) AS INTEGER (a status_t - 0/B_OK on success), supplied via
''' `@YourFunctionName`. Not setting a callback keeps Haiku's own
''' default (always OK).
SUB HScreenSaverSetInitCheckCallback(BYVAL s AS HScreenSaver, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_screensaver_set_init_check_callback(s.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied FUNCTION taking (userData AS
''' ANY PTR, view AS ANY PTR, preview AS INTEGER) AS INTEGER (a
''' status_t). `view` is the real, daemon-owned BView to draw into -
''' this package's own view.bas drawing primitives (HViewSetHighColor/
''' HViewFillRect/HViewDrawString/...) all take a plain view handle, so
''' the same functions already used for ordinary custom drawing work
''' here unchanged. `preview` is nonzero when running inside the
''' Screensaver preferences panel's own small preview thumbnail rather
''' than full-screen.
SUB HScreenSaverSetStartSaverCallback(BYVAL s AS HScreenSaver, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_screensaver_set_start_saver_callback(s.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY PTR).
SUB HScreenSaverSetStopSaverCallback(BYVAL s AS HScreenSaver, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_screensaver_set_stop_saver_callback(s.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, view AS ANY PTR, frame AS INTEGER) - called repeatedly (every
''' TickSize microseconds, see below) with the same real, daemon-owned
''' `view` StartSaver already received; `frame` counts up from 0.
SUB HScreenSaverSetDrawCallback(BYVAL s AS HScreenSaver, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_screensaver_set_draw_callback(s.handle, cb, userData)
END SUB

''' Microseconds between Draw calls (default: a real Haiku-chosen
''' value - call TickSize to read it rather than assuming).
SUB HScreenSaverSetTickSize(BYVAL s AS HScreenSaver, BYVAL tickSize AS LONGINT)
    CALL eb_haiku_screensaver_set_tick_size(s.handle, tickSize)
END SUB

FUNCTION HScreenSaverTickSize(BYVAL s AS HScreenSaver) AS LONGINT
    HScreenSaverTickSize = eb_haiku_screensaver_tick_size(s.handle)
END FUNCTION

''' Frame-count animation cycle: `onCount` frames of real Draw calls,
''' then `offCount` frames skipped, repeating.
SUB HScreenSaverSetLoop(BYVAL s AS HScreenSaver, BYVAL onCount AS INTEGER, BYVAL offCount AS INTEGER)
    CALL eb_haiku_screensaver_set_loop(s.handle, onCount, offCount)
END SUB

FUNCTION HScreenSaverLoopOnCount(BYVAL s AS HScreenSaver) AS INTEGER
    HScreenSaverLoopOnCount = eb_haiku_screensaver_loop_on_count(s.handle)
END FUNCTION

FUNCTION HScreenSaverLoopOffCount(BYVAL s AS HScreenSaver) AS INTEGER
    HScreenSaverLoopOffCount = eb_haiku_screensaver_loop_off_count(s.handle)
END FUNCTION
