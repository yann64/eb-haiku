' Custom drawing into a view - a filled rectangle, a stroked border, a
' diagonal line, and some text. HShimViewInvalidate requests a redraw
' (the only safe way to trigger one from outside the Draw callback
' itself).

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

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-DrawingExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 400, 300, "eb-haiku drawing example", H_QUIT_ON_WINDOW_CLOSE)

gCanvas = HShimViewCreate(0, 0, 280, 180, "canvas", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(gCanvas, @OnDraw, 0)
CALL HWindowAddChild(w, gCanvas.handle)

CALL HWindowShow(w)
CALL Sleep(2000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
