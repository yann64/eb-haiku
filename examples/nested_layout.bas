' A layout nested inside an ordinary view (not just directly on the
' window), plus a control pinned to an explicit size and alignment.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-NestedLayoutExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku nested layout example", H_QUIT_ON_WINDOW_CLOSE)

DIM outer AS HGroupLayout
outer = HGroupLayoutCreate(H_VERTICAL, 12)
CALL HWindowSetLayout(w, outer.handle)

DIM inner AS HGroupLayout
inner = HGroupLayoutCreate(H_HORIZONTAL, 4)

DIM innerView AS HView
innerView = HViewCreate(0, 0, 0, 0, "innerContainer", H_FOLLOW_ALL, 0)
CALL HViewSetLayout(innerView.handle, inner.handle)
CALL HLayoutAddView(outer.handle, innerView.handle)

DIM lbl1 AS HStringView
lbl1 = HStringViewCreate(0, 0, 0, 0, "lbl1", "Left")
CALL HLayoutAddView(inner.handle, lbl1.handle)

DIM lbl2 AS HStringView
lbl2 = HStringViewCreate(0, 0, 0, 0, "lbl2", "Right")
CALL HLayoutAddView(inner.handle, lbl2.handle)

DIM btn AS HButton
btn = HButtonCreate(0, 0, 0, 0, "bigbutton", "Big Button", 2222)
CALL HViewSetExplicitMinSize(btn.handle, 200, 60)
CALL HViewSetExplicitAlignment(btn.handle, H_ALIGN_CENTER, H_ALIGN_MIDDLE)
CALL HLayoutAddView(outer.handle, btn.handle)

CALL HWindowShow(w)
CALL Sleep(2000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
