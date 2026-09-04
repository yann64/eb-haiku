' Idiomatic layer: HTimer (BMessageRunner) - added for the eb-gui
' universal cross-toolkit GUI API. Real Haiku's own periodic-message
' primitive, BMessageRunner, doesn't match the Start/Stop/SetSingleShot/
' IsActive shape any more directly than GLib's g_timeout_add did for
' eb-gtk4's own GtkTimer - a real BMessageRunner is effectively
' one-shot-lifecycle, so HTimerStart always recreates the underlying
' BMessageRunner rather than assuming it can be restarted in place (see
' native/shim_interface.cpp's own ShimTimer for the native-side detail).
' Delivery goes through a dedicated HHandler (handler.bas) rather than
' the owning window's own shared MessageReceived callback, giving each
' timer a genuinely independent, per-instance callback.

#include once "raw/haiku_shim_interface.bas"
#include once "handler.bas"

TYPE HTimer
    handle AS ANY PTR
    target AS HHandler
END TYPE

''' `w` is required (the timer's own HHandler needs a window's BLooper
''' to attach to, matching eb-qt6's own NewQTimer(parent) requirement -
''' unlike eb-gtk4's parentless GtkTimer).
FUNCTION HTimerCreate(BYVAL w AS HWindow) AS HTimer
    DIM t AS HTimer
    t.target = HHandlerCreate()
    CALL HWindowAddHandler(w, t.target)
    t.handle = eb_haiku_timer_create(t.target.handle)
    HTimerCreate = t
END FUNCTION

SUB HTimerSetInterval(BYVAL t AS HTimer, BYVAL microseconds AS LONGINT)
    CALL eb_haiku_timer_set_interval(t.handle, microseconds)
END SUB

''' If set, the timer fires once, then stops.
SUB HTimerSetSingleShot(BYVAL t AS HTimer, BYVAL singleShot AS INTEGER)
    CALL eb_haiku_timer_set_single_shot(t.handle, singleShot)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR) - no return value, matching every other periodic-tick callback
''' in this ecosystem.
SUB HTimerConnectTimeout(BYVAL t AS HTimer, cb AS ANY PTR, userData AS ANY PTR)
    CALL HHandlerSetCallback(t.target, cb, userData)
END SUB

''' (Re)starts the timer at its currently configured interval/single-
''' shot setting - always recreates the underlying BMessageRunner (see
''' this file's own top comment).
SUB HTimerStart(BYVAL t AS HTimer)
    CALL eb_haiku_timer_start(t.handle)
END SUB

SUB HTimerStop(BYVAL t AS HTimer)
    CALL eb_haiku_timer_stop(t.handle)
END SUB

FUNCTION HTimerIsActive(BYVAL t AS HTimer) AS INTEGER
    HTimerIsActive = eb_haiku_timer_is_active(t.handle)
END FUNCTION

''' Frees the timer's own plain heap allocation (not a BHandler itself -
''' its target HHandler is owned by the window's BLooper once attached,
''' matching this package's own existing stock-controls convention of
''' Haiku owning/destroying attached objects automatically).
SUB HTimerDestroy(BYVAL t AS HTimer)
    CALL eb_haiku_timer_destroy(t.handle)
END SUB
