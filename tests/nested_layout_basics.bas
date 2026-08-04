' Step 1+2: a layout nested inside an ordinary view (not just directly
' on the window), a control with an explicit min size and alignment,
' and BGroupLayout's own extended setters (spacing/orientation/weight).
' Verified visually via an external screenshot (see
' scripts/haiku_verify.sh).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-NestedLayoutTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku nested layout test", H_QUIT_ON_WINDOW_CLOSE)

' The window's own top-level layout: a vertical group containing one
' plain container view (itself laid out horizontally) and one button
' pinned to an explicit large size.
DIM outer AS HGroupLayout
outer = HGroupLayoutCreate(H_VERTICAL, 8)
CALL HGroupLayoutSetSpacing(outer, 12)
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

CALL HGroupLayoutSetItemWeight(outer, 0, 1)
CALL HGroupLayoutSetItemWeight(outer, 1, 0)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(2000)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "nested layout test ok"
