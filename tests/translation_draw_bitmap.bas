' Translation Kit step 2 (visual half): load a real PNG via HGetBitmap
' and actually draw it in a window with HViewDrawBitmap - verified by
' screenshot (see scripts/haiku_verify.sh's own note on why GUI/drawing
' correctness can only be checked by looking at it).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM gCanvas AS HShimView
DIM gBitmap AS HBitmap

SUB OnDraw(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HViewDrawBitmap(gCanvas.handle, gBitmap.handle, 10, 10)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-DrawBitmapTest")

DIM f AS HFile
f = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(f) <> 0 THEN
    PRINT "FAIL: could not open fixture PNG"
    CALL ExitProcess(1)
END IF

gBitmap = HGetBitmap(f.handle)
IF gBitmap.handle = 0 THEN
    PRINT "FAIL: HGetBitmap returned a null handle"
    CALL ExitProcess(1)
END IF
CALL HFileFree(f)

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 220, "eb-haiku DrawBitmap test", H_QUIT_ON_WINDOW_CLOSE)

gCanvas = HShimViewCreate(0, 0, 300, 100, "canvas", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(gCanvas, @OnDraw, 0)
CALL HWindowAddChild(w, gCanvas.handle)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(1500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HBitmapFree(gBitmap)
CALL HApplicationFree(app)

PRINT "draw bitmap test ok"
