' Idiomatic layer: BWindow (via the native shim's own ShimWindow - see
' native/shim_interface.cpp's own top comment for why a real C++
' subclass is unavoidable here).
'
' Threading: once HWindowShow is called, this window runs its own
' message loop on its own separate thread - HWindowSetMessageReceived-
' Callback/HWindowSetQuitRequestedCallback/HWindowSetFrameResizedCallback
' are all invoked from THAT thread, never whichever thread called
' HApplicationRun. See this package's own README for the intended safe
' usage pattern (do nothing on the Run()-calling thread afterward - all
' real logic lives in these callbacks, which Haiku's own per-window
' message queue already serializes one at a time).

#include once "raw/haiku_shim_interface.bas"

TYPE HWindow
    handle AS ANY PTR
END TYPE

''' Creates a titled window with the given frame and title - not shown
''' until HWindowShow is called.
FUNCTION HWindowCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, title AS ZSTRING, BYVAL flags AS UINTEGER) AS HWindow
    DIM w AS HWindow
    w.handle = eb_haiku_window_create(left, top, right, bottom, title, flags)
    HWindowCreate = w
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, messageHandle AS ANY PTR), supplied via `@YourSubName` - see
''' docs/reference/namespaces-pointers-unions.md's own `@ProcName`
''' section. `messageHandle` is a real BMessage - wrap it via `DIM msg
''' AS HMessage : msg.handle = messageHandle` to use this package's own
''' Phase 1 HMessage* functions on it.
SUB HWindowSetMessageReceivedCallback(BYVAL w AS HWindow, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_window_set_message_received_callback(w.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied FUNCTION taking (userData AS
''' ANY PTR) AS INTEGER - nonzero allows the window to close, 0 refuses.
''' Not setting a callback keeps Haiku's own default (always allow).
SUB HWindowSetQuitRequestedCallback(BYVAL w AS HWindow, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_window_set_quit_requested_callback(w.handle, cb, userData)
END SUB

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, newWidth AS SINGLE, newHeight AS SINGLE) - only fires if the
''' window was created with the H_FRAME_EVENTS flag.
SUB HWindowSetFrameResizedCallback(BYVAL w AS HWindow, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_window_set_frame_resized_callback(w.handle, cb, userData)
END SUB

SUB HWindowShow(BYVAL w AS HWindow)
    CALL eb_haiku_window_show(w.handle)
END SUB

SUB HWindowHide(BYVAL w AS HWindow)
    CALL eb_haiku_window_hide(w.handle)
END SUB

SUB HWindowAddChild(BYVAL w AS HWindow, BYVAL view AS ANY PTR)
    CALL eb_haiku_window_add_child(w.handle, view)
END SUB

SUB HWindowSetLayout(BYVAL w AS HWindow, BYVAL layout AS ANY PTR)
    CALL eb_haiku_window_set_layout(w.handle, layout)
END SUB

''' Requests the window to close - safe to call from any thread (posts
''' a real B_QUIT_REQUESTED message rather than calling Quit()
''' directly). Do not free/destroy an HWindow yourself: once its
''' QuitRequested (default or your own callback) allows the close,
''' Haiku deletes the real BWindow automatically - there is no
''' HWindowFree in this package.
SUB HWindowClose(BYVAL w AS HWindow)
    CALL eb_haiku_window_close(w.handle)
END SUB

SUB HWindowSetTitle(BYVAL w AS HWindow, title AS ZSTRING)
    CALL eb_haiku_window_set_title(w.handle, title)
END SUB

SUB HWindowMoveTo(BYVAL w AS HWindow, BYVAL x AS SINGLE, BYVAL y AS SINGLE)
    CALL eb_haiku_window_move_to(w.handle, x, y)
END SUB

SUB HWindowResizeTo(BYVAL w AS HWindow, BYVAL width AS SINGLE, BYVAL height AS SINGLE)
    CALL eb_haiku_window_resize_to(w.handle, width, height)
END SUB

''' Recursively enables/disables every control (BButton/BTextControl/...)
''' directly or indirectly attached to `w` - Haiku has no BWindow- or
''' BView-level "enabled" concept of its own (unlike GTK4's real
''' recursive widget sensitivity), so this walks the real view tree.
SUB HWindowSetEnabled(BYVAL w AS HWindow, BYVAL enabled AS INTEGER)
    CALL eb_haiku_window_set_enabled(w.handle, enabled)
END SUB

''' Real Haiku modal: makes `w` a modal subset of `parent` - best set
''' before `w` is first shown for reliable behavior. `HWindowClearModal`
''' needs the SAME `parent` reference back (real
''' BWindow::RemoveFromSubset requires it) - callers should keep track
''' of which window a given `w` was made modal to.
SUB HWindowSetModal(BYVAL w AS HWindow, BYVAL parent AS HWindow)
    CALL eb_haiku_window_set_modal(w.handle, parent.handle)
END SUB

SUB HWindowClearModal(BYVAL w AS HWindow, BYVAL parent AS HWindow)
    CALL eb_haiku_window_clear_modal(w.handle, parent.handle)
END SUB
