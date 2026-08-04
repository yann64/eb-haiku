' BSplitView - two resizable panes with a draggable splitter between
' them.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM leftView AS HShimView
DIM rightView AS HShimView

SUB OnDrawLeft(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HViewSetHighColor(leftView.handle, 200, 60, 60)
    CALL HViewFillRect(leftView.handle, 0, 0, 500, 500)
    CALL HViewSetHighColor(leftView.handle, 0, 0, 0)
    CALL HViewDrawString(leftView.handle, "Left pane", 10, 20)
END SUB

SUB OnDrawRight(userData AS ANY PTR, updateLeft AS SINGLE, updateTop AS SINGLE, updateRight AS SINGLE, updateBottom AS SINGLE)
    CALL HViewSetHighColor(rightView.handle, 60, 60, 200)
    CALL HViewFillRect(rightView.handle, 0, 0, 500, 500)
    CALL HViewSetHighColor(rightView.handle, 0, 0, 0)
    CALL HViewDrawString(rightView.handle, "Right pane", 10, 20)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-SplitViewExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku split view example", H_QUIT_ON_WINDOW_CLOSE)

DIM outer AS HGroupLayout
outer = HGroupLayoutCreate(H_VERTICAL, 0)
CALL HWindowSetLayout(w, outer.handle)

DIM split AS HSplitView
split = HSplitViewCreate(H_HORIZONTAL, 4)
CALL HSplitViewSetInsets(split, 8, 8, 8, 8)
CALL HLayoutAddView(outer.handle, split.handle)

leftView = HShimViewCreate(0, 0, 0, 0, "leftPane", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HSplitViewAddChild(split, leftView.handle, 1)

rightView = HShimViewCreate(0, 0, 0, 0, "rightPane", H_FOLLOW_ALL, H_WILL_DRAW)
CALL HSplitViewAddChild(split, rightView.handle, 1)

CALL HShimViewSetDrawCallback(leftView, @OnDrawLeft, 0)
CALL HShimViewSetDrawCallback(rightView, @OnDrawRight, 0)

CALL HWindowShow(w)
CALL Sleep(2000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
