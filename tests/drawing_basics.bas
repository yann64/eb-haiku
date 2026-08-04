' Slice 3: a window with a custom-drawn view - a filled rectangle, a
' stroked rectangle, a diagonal line, and some text - plus a registered
' (but not triggerable over SSH - there's no real mouse hardware here)
' MouseDown callback, confirming registration itself doesn't break
' anything. Verified visually via an external screenshot (see
' scripts/haiku_verify.sh) - there is no way to check "did it draw the
' right pixels" other than looking at it. Invalidate() is exercised
' directly (queuing a real redraw) to confirm it doesn't crash.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM gCanvas AS HShimView

SUB OnDraw(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HViewSetHighColor(gCanvas.handle, 200, 60, 60)
    CALL HViewFillRect(gCanvas.handle, 10, 10, 120, 80)

    CALL HViewSetHighColor(gCanvas.handle, 0, 0, 0)
    CALL HViewStrokeRect(gCanvas.handle, 10, 10, 120, 80)
    CALL HViewStrokeLine(gCanvas.handle, 10, 10, 120, 80)
    CALL HViewDrawString(gCanvas.handle, "eb-haiku drawing", 10, 110)
END SUB

SUB OnMouseDown(userData AS ANY PTR, x AS SINGLE, y AS SINGLE)
    PRINT "mouse down"
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-DrawingBasicsTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 400, 300, "eb-haiku drawing test", H_QUIT_ON_WINDOW_CLOSE)

gCanvas = HShimViewCreate(0, 0, 280, 180, "canvas", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(gCanvas, @OnDraw, 0)
CALL HShimViewSetMouseDownCallback(gCanvas, @OnMouseDown, 0)
CALL HWindowAddChild(w, gCanvas.handle)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(1500) ' visible for an external screenshot

CALL HShimViewInvalidate(gCanvas) ' confirms a manually-requested redraw doesn't crash
CALL Sleep(300)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "drawing basics test ok"
