' BTextView - real multi-line, plain-text editing (no shim subclass
' needed, unlike BWindow/BView - see src/textview.bas's own top
' comment). A minimal notes-editor-shaped window.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-TextEditorExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 500, 400, "eb-haiku text editor example", H_QUIT_ON_WINDOW_CLOSE)

DIM tv AS HTextView
tv = HTextViewCreate(10, 10, 480, 380, "editor")
CALL HTextViewSetWordWrap(tv, 1)
CALL HTextViewSetText(tv, "Type here..." & Chr(10) & Chr(10) & "This is a real, editable BTextView.")
CALL HWindowAddChild(w, tv.handle)

CALL HWindowShow(w)
CALL Sleep(1500)

PRINT "text=", HTextViewGetText(tv)
PRINT "length=", HTextViewTextLength(tv)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
