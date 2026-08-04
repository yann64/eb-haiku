' Slice 4: a window using BGroupLayout (a vertical stack of a label, a
' text field, and a button) instead of manual frame positioning for
' each control. Verified visually via an external screenshot (see
' scripts/haiku_verify.sh) - layout correctness (spacing/sizing) is
' only meaningfully checkable by looking at it.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-LayoutBasicsTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 360, 220, "eb-haiku layout test", H_QUIT_ON_WINDOW_CLOSE)

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
PRINT "shown ok"

CALL Sleep(1500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "layout basics test ok"
