' BTextView - real per-range color styling (SetFontAndColor). Real
' BTextView defaults to IsStylable()=false, in which case a color
' change silently applies to the ENTIRE text instead of just the given
' range - HTextViewSetStylable(tv, 1) must be called first (see
' src/textview.bas's own doc comment).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-StyledTextExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 300, "eb-haiku styled text example", H_QUIT_ON_WINDOW_CLOSE)

DIM tv AS HTextView
tv = HTextViewCreate(10, 10, 400, 280, "styled")
CALL HTextViewSetText(tv, "Some plain text, and some RED text.")
CALL HWindowAddChild(w, tv.handle)

CALL HTextViewSetStylable(tv, 1)
' "RED" spans offsets [26, 29) in the text above.
CALL HTextViewSetColor(tv, 26, 29, 255, 0, 0, 255)

CALL HWindowShow(w)
CALL Sleep(1500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
