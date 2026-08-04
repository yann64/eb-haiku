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

' ---- Real per-range color styling - no BFont binding needed (see
' textview.bas's own top comment). IMPORTANT, confirmed by direct
' reproduction: HTextViewSetStylable(tv, 1) must be called first - real
' BTextView defaults to IsStylable()=false, in which case the color
' change below would silently apply to the ENTIRE text instead of just
' [0, 5). ----

IF HTextViewIsStylable(tv) <> 0 THEN
    PRINT "FAIL: HTextViewIsStylable should default to false"
    CALL ExitProcess(1)
END IF
CALL HTextViewSetStylable(tv, 1)
IF HTextViewIsStylable(tv) <> 1 THEN
    PRINT "FAIL: HTextViewIsStylable should be true after SetStylable(1)"
    CALL ExitProcess(1)
END IF

CALL HTextViewSetColor(tv, 0, 5, 255, 0, 0, 255)
DIM r AS UBYTE
DIM g AS UBYTE
DIM b AS UBYTE
DIM a AS UBYTE
CALL HTextViewGetColor(tv, 2, r, g, b, a)
PRINT "color at offset 2=(", r, ",", g, ",", b, ",", a, ")"
IF r <> 255 OR g <> 0 OR b <> 0 OR a <> 255 THEN
    PRINT "FAIL: expected red (255,0,0,255) in the styled range"
    CALL ExitProcess(1)
END IF

' A different range should still have the real default color, not red.
CALL HTextViewGetColor(tv, 10, r, g, b, a)
PRINT "color at offset 10=(", r, ",", g, ",", b, ",", a, ")"
IF r = 255 AND g = 0 AND b = 0 THEN
    PRINT "FAIL: offset 10 should not have been colored red"
    CALL ExitProcess(1)
END IF
PRINT "SetColor/GetColor ok"

CALL HWindowShow(w)
CALL Sleep(500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "textview basics test ok"
