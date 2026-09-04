' Idiomatic layer: stock controls (BButton/BStringView/BTextControl) -
' plain, non-subclassed. A click/invocation posts the control's own
' `what` message to its target, which Haiku sets to the window it's
' attached to automatically once shown - so it arrives at the window's
' own MessageReceived callback (HWindowSetMessageReceivedCallback, see
' window.bas), not a separate per-control callback. Add any of these to
' a window/view via HWindowAddChild/HViewAddChild, passing `.handle`
' directly - each is a real BView under the hood.

#include once "raw/haiku_shim_interface.bas"
#include once "handler.bas"

TYPE HButton
    handle AS ANY PTR
END TYPE

''' Creates a button - clicking it posts a message with the given
''' `what` code to its target (see this file's own top comment).
FUNCTION HButtonCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, label AS ZSTRING, BYVAL what AS UINTEGER) AS HButton
    DIM b AS HButton
    b.handle = eb_haiku_button_create(left, top, right, bottom, name, label, what)
    HButtonCreate = b
END FUNCTION

''' Triggers the button exactly as a real click would - a normal Haiku
''' API (BInvoker::Invoke), not just a testing hook; also useful for
''' programmatically driving a button (e.g. a "Cancel" keyboard
''' shortcut invoking the Cancel button) from elsewhere in a program.
SUB HButtonInvoke(BYVAL b AS HButton)
    CALL eb_haiku_button_invoke(b.handle)
END SUB

''' Changes the button's own label text.
SUB HButtonSetLabel(BYVAL b AS HButton, label AS ZSTRING)
    CALL eb_haiku_button_set_label(b.handle, label)
END SUB

FUNCTION HButtonGetLabel(BYVAL b AS HButton) AS ZSTRING
    HButtonGetLabel = eb_haiku_button_get_label(b.handle)
END FUNCTION

''' Redirects `b`'s own invocation message to `handler` instead of
''' whichever window it happens to be attached to - the same real
''' per-object callback mechanism HMenuItemSetTarget gives menu items
''' (`handler` must already be attached to a window's BLooper via
''' HWindowAddHandler).
SUB HButtonSetTarget(BYVAL b AS HButton, BYVAL handler AS HHandler)
    CALL eb_haiku_button_set_target(b.handle, handler.handle)
END SUB

''' Enables/disables a control (BButton or HTextControl - see this
''' file's own HControlSetEnabled/IsEnabled doc comment below for why
''' this takes a plain ANY PTR rather than a specific TYPE).
SUB HControlSetEnabled(BYVAL control AS ANY PTR, BYVAL enabled AS INTEGER)
    CALL eb_haiku_control_set_enabled(control, enabled)
END SUB

''' Whether a control currently accepts input - see HControlSetEnabled.
''' Both stock controls (HButton, HTextControl) share Haiku's own
''' BControl base, so this one function works on either's `.handle`
''' directly rather than needing a per-type overload.
FUNCTION HControlIsEnabled(BYVAL control AS ANY PTR) AS INTEGER
    HControlIsEnabled = eb_haiku_control_is_enabled(control)
END FUNCTION

TYPE HStringView
    handle AS ANY PTR
END TYPE

''' Creates a plain, non-editable text label.
FUNCTION HStringViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, text AS ZSTRING) AS HStringView
    DIM s AS HStringView
    s.handle = eb_haiku_stringview_create(left, top, right, bottom, name, text)
    HStringViewCreate = s
END FUNCTION

SUB HStringViewSetText(BYVAL s AS HStringView, text AS ZSTRING)
    CALL eb_haiku_stringview_set_text(s.handle, text)
END SUB

FUNCTION HStringViewGetText(BYVAL s AS HStringView) AS ZSTRING
    HStringViewGetText = eb_haiku_stringview_get_text(s.handle)
END FUNCTION

TYPE HTextControl
    handle AS ANY PTR
END TYPE

''' Creates a labeled, editable text field - pressing Enter in it (or
''' losing focus, depending on Haiku's own defaults) posts a message
''' with the given `what` code to its target, same as HButton.
FUNCTION HTextControlCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING, label AS ZSTRING, initialText AS ZSTRING, BYVAL what AS UINTEGER) AS HTextControl
    DIM t AS HTextControl
    t.handle = eb_haiku_textcontrol_create(left, top, right, bottom, name, label, initialText, what)
    HTextControlCreate = t
END FUNCTION

SUB HTextControlSetText(BYVAL t AS HTextControl, text AS ZSTRING)
    CALL eb_haiku_textcontrol_set_text(t.handle, text)
END SUB

FUNCTION HTextControlGetText(BYVAL t AS HTextControl) AS ZSTRING
    HTextControlGetText = eb_haiku_textcontrol_get_text(t.handle)
END FUNCTION
