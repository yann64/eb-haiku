' Loads a real PNG from disk with HGetBitmap and draws it in a window
' with HViewDrawBitmap - the Translation Kit's own compelling
' end-to-end demo. Requires an HApplication to exist first (see this
' package's own README "Threading" section - Translation Kit functions
' hang indefinitely without one).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM gCanvas AS HShimView
DIM gBitmap AS HBitmap

SUB OnDraw(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HViewDrawBitmap(gCanvas.handle, gBitmap.handle, 10, 10)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-LoadImageExample")

DIM f AS HFile
f = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(f) <> 0 THEN
    PRINT "could not open the image file"
    CALL ExitProcess(1)
END IF

gBitmap = HGetBitmap(f.handle)
CALL HFileFree(f)
IF gBitmap.handle = 0 THEN
    PRINT "could not decode the image"
    CALL ExitProcess(1)
END IF

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 220, "eb-haiku image example", H_QUIT_ON_WINDOW_CLOSE)

gCanvas = HShimViewCreate(0, 0, 300, 100, "canvas", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(gCanvas, @OnDraw, 0)
CALL HWindowAddChild(w, gCanvas.handle)

CALL HWindowShow(w)
CALL Sleep(2000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HBitmapFree(gBitmap)
CALL HApplicationFree(app)
