' BLocker - a real mutex, closing the "eBasic has no locking
' primitives" gap this package's own README used to document as an
' unsolved risk. Real cross-thread protection: two window Draw
' callbacks (each running on its own real thread) safely share one
' counter by locking around every access.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM gLocker AS HLocker
gLocker = HLockerCreate()
DIM gCounter AS INTEGER
gCounter = 0

SUB OnDrawIncrement(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HLockerLock(gLocker)
    gCounter = gCounter + 1
    CALL HLockerUnlock(gLocker)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-LockingExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 300, 200, "eb-haiku locking example", H_QUIT_ON_WINDOW_CLOSE)
DIM canvas AS HShimView
canvas = HShimViewCreate(0, 0, 180, 80, "canvas", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HShimViewSetDrawCallback(canvas, @OnDrawIncrement, 0)
CALL HWindowAddChild(w, canvas.handle)

CALL HWindowShow(w)
CALL HShimViewInvalidate(canvas)
CALL Sleep(500)

PRINT "counter=", gCounter   ' 1

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
CALL HLockerFree(gLocker)
