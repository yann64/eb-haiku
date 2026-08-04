' Idiomatic layer: BTextView - real multi-line, plain-text editing (a
' concrete BView subclass needing no shim subclass of its own, unlike
' BWindow/BView - Text() returns a plain const char*, so it marshals
' via ZSTRING exactly like HStringViewGetText/HTextControlGetText
' already do). Add to a window/view via HWindowAddChild/HViewAddChild,
' passing `.handle` directly - a real BView under the hood.
'
' Real per-character-range *color* styling is bound (HTextViewSetColor/
' GetColor, v0.9.0) - font family/size/style changes are not: BFont
' itself isn't bound anywhere in this package (a separate, larger
' future addition), and SetFontAndColor's own font parameter is safe to
' pass as nullptr with mode=0 (confirmed by direct reproduction), so
' color-only styling needs no BFont handle at all.

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

''' Whether real per-range font/color styling (HTextViewSetColor below)
''' actually takes effect - real Haiku default is false. IMPORTANT,
''' confirmed by direct reproduction: with this off (the real default),
''' HTextViewSetColor's own color change is NOT scoped to its given
''' range at all - it silently applies to the ENTIRE text instead. Call
''' HTextViewSetStylable(t, 1) before ever calling HTextViewSetColor.
SUB HTextViewSetStylable(BYVAL t AS HTextView, BYVAL stylable AS INTEGER)
    CALL eb_haiku_textview_set_stylable(t.handle, stylable)
END SUB

FUNCTION HTextViewIsStylable(BYVAL t AS HTextView) AS INTEGER
    HTextViewIsStylable = eb_haiku_textview_is_stylable(t.handle)
END FUNCTION

''' Sets the real display color of the text range [start, end) to
''' (r, g, b, a) - font/style unaffected (no BFont binding needed for
''' this, see this file's own top comment). REQUIRES
''' HTextViewSetStylable(t, 1) to have been called first - see its own
''' doc comment for why.
SUB HTextViewSetColor(BYVAL t AS HTextView, BYVAL start AS INTEGER, BYVAL end_ AS INTEGER, BYVAL r AS UBYTE, BYVAL g AS UBYTE, BYVAL b AS UBYTE, BYVAL a AS UBYTE)
    CALL eb_haiku_textview_set_color(t.handle, start, end_, r, g, b, a)
END SUB

''' Fills the 4 BYREF out-params with the real color in effect at the
''' start of the run containing `offset`.
SUB HTextViewGetColor(BYVAL t AS HTextView, BYVAL offset AS INTEGER, BYREF outR AS UBYTE, BYREF outG AS UBYTE, BYREF outB AS UBYTE, BYREF outA AS UBYTE)
    DIM buf(3) AS UBYTE
    CALL eb_haiku_textview_get_color(t.handle, offset, @buf(0), @buf(1), @buf(2), @buf(3))
    outR = buf(0)
    outG = buf(1)
    outB = buf(2)
    outA = buf(3)
END SUB
