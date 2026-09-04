' Idiomatic layer: ShimHandler - a small, reusable per-object callback
' target, added for the eb-gui universal cross-toolkit GUI API (see
' eb-gui-haiku). Real Haiku's own per-object callback story is thin:
' BMenuItem/BMessageRunner (menu.bas/timer.bas) both deliver via a
' BMessage sent to a *target* BHandler, which defaults to the window
' itself - fine for this package's own existing
' HWindowSetMessageReceivedCallback (one shared dispatch point), but
' eb-gui's contract needs a genuinely per-action/per-timer callback
' (unlike GTK4's GSimpleAction "activate" signal or Qt6's
' QAction::triggered, which are real per-object signals Haiku has no
' equivalent of). Each action/timer gets its OWN HHandler, added to the
' owning window's own BLooper, and set as the real invocation target -
' see native/shim_interface.h's own top comment on ShimHandler for the
' full native-side rationale.

#include once "raw/haiku_shim_interface.bas"
#include once "window.bas"

TYPE HHandler
    handle AS ANY PTR
END TYPE

FUNCTION HHandlerCreate() AS HHandler
    DIM h AS HHandler
    h.handle = eb_haiku_handler_create()
    HHandlerCreate = h
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR) - fires unconditionally whenever `h` receives ANY message,
''' since one handler is always dedicated to exactly one action/timer,
''' never shared.
SUB HHandlerSetCallback(BYVAL h AS HHandler, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_handler_set_callback(h.handle, cb, userData)
END SUB

''' Attaches `h` to `w`'s own BLooper - required before `h` can be used
''' as a real invocation target (HMenuItemSetTarget, HTimerCreate).
SUB HWindowAddHandler(BYVAL w AS HWindow, BYVAL h AS HHandler)
    CALL eb_haiku_window_add_handler(w.handle, h.handle)
END SUB
