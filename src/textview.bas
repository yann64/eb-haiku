' Idiomatic layer: BTextView - real multi-line, plain-text editing (a
' concrete BView subclass needing no shim subclass of its own, unlike
' BWindow/BView - Text() returns a plain const char*, so it marshals
' via ZSTRING exactly like HStringViewGetText/HTextControlGetText
' already do). Add to a window/view via HWindowAddChild/HViewAddChild,
' passing `.handle` directly - a real BView under the hood.
'
' Styled text (text_run_array) is deliberately not bound - plain-text
' editing only, matching this package's own "smallest useful slice
' first" discipline.

#include once "raw/haiku_shim_interface.bas"

TYPE HTextView
    handle AS ANY PTR
END TYPE

''' Creates a multi-line text view - editable by default (real Haiku's
''' own BTextView default).
FUNCTION HTextViewCreate(BYVAL left AS SINGLE, BYVAL top AS SINGLE, BYVAL right AS SINGLE, BYVAL bottom AS SINGLE, name AS ZSTRING) AS HTextView
    DIM t AS HTextView
    t.handle = eb_haiku_textview_create(left, top, right, bottom, name)
    HTextViewCreate = t
END FUNCTION

SUB HTextViewSetText(BYVAL t AS HTextView, text AS ZSTRING)
    CALL eb_haiku_textview_set_text(t.handle, text)
END SUB

FUNCTION HTextViewGetText(BYVAL t AS HTextView) AS ZSTRING
    HTextViewGetText = eb_haiku_textview_get_text(t.handle)
END FUNCTION

FUNCTION HTextViewTextLength(BYVAL t AS HTextView) AS INTEGER
    HTextViewTextLength = eb_haiku_textview_text_length(t.handle)
END FUNCTION

''' Whether long lines wrap to fit the view's own width (real Haiku
''' default is on).
SUB HTextViewSetWordWrap(BYVAL t AS HTextView, BYVAL wrap AS INTEGER)
    CALL eb_haiku_textview_set_word_wrap(t.handle, wrap)
END SUB

''' Toggles real user-editability - a non-editable HTextView still
''' supports selection/copy, just not typing.
SUB HTextViewMakeEditable(BYVAL t AS HTextView, BYVAL editable AS INTEGER)
    CALL eb_haiku_textview_make_editable(t.handle, editable)
END SUB

''' Selects the real text range [start, end) - pass the same value
''' twice to just move the caret with no selection.
SUB HTextViewSelect(BYVAL t AS HTextView, BYVAL start AS INTEGER, BYVAL end_ AS INTEGER)
    CALL eb_haiku_textview_select(t.handle, start, end_)
END SUB
