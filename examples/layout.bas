' BGroupLayout arranges child views in a column (or row) automatically,
' instead of positioning each one with a manual frame.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-LayoutExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 360, 220, "eb-haiku layout example", H_QUIT_ON_WINDOW_CLOSE)

DIM layout AS HGroupLayout
layout = HGroupLayoutCreate(H_VERTICAL, 8)
CALL HWindowSetLayout(w, layout.handle)

DIM lbl AS HStringView
lbl = HStringViewCreate(0, 0, 0, 0, "label", "Laid out vertically:")
CALL HGroupLayoutAddView(layout, lbl.handle)

DIM txt AS HTextControl
txt = HTextControlCreate(0, 0, 0, 0, "textfield", "Name:", "eBasic", 3333)
CALL HGroupLayoutAddView(layout, txt.handle)

DIM btn AS HButton
btn = HButtonCreate(0, 0, 0, 0, "clickme", "OK", 2222)
CALL HGroupLayoutAddView(layout, btn.handle)

CALL HWindowShow(w)
CALL Sleep(2000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
