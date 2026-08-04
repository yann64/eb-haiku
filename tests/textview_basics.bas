' Interface Kit: BTextView - real multi-line, plain-text editing. A
' concrete BView subclass needing no shim subclass of its own (unlike
' BWindow/BView) - added to a window exactly like any other stock
' control.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-TextViewBasicsTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 300, "eb-haiku textview test", H_QUIT_ON_WINDOW_CLOSE)

DIM tv AS HTextView
tv = HTextViewCreate(20, 20, 380, 200, "textview")
CALL HWindowAddChild(w, tv.handle)

DIM expectedText AS STRING
expectedText = "Hello from eb-haiku" & Chr(10) & "a second line"
CALL HTextViewSetText(tv, expectedText)
DIM txt AS STRING
txt = HTextViewGetText(tv)
PRINT "text=", txt
IF txt <> expectedText THEN
    PRINT "FAIL: text round-trip mismatch"
    CALL ExitProcess(1)
END IF

DIM textLen AS INTEGER
textLen = HTextViewTextLength(tv)
PRINT "text length=", textLen
IF textLen <> Len(txt) THEN
    PRINT "FAIL: expected length ", Len(txt), ", got ", textLen
    CALL ExitProcess(1)
END IF

CALL HTextViewSetWordWrap(tv, 1)
CALL HTextViewMakeEditable(tv, 0)
CALL HTextViewSelect(tv, 0, 5)
PRINT "SetWordWrap/MakeEditable/Select ran ok"

CALL HWindowShow(w)
CALL Sleep(500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "textview basics test ok"
