' Step 6: BSpaceLayoutItem - glue between two buttons in a horizontal
' BGroupLayout, pushing one to each end instead of them sitting side by
' side. Verified visually via an external screenshot (see
' scripts/haiku_verify.sh).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-SpaceLayoutItemTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 180, "eb-haiku space layout item test", H_QUIT_ON_WINDOW_CLOSE)

DIM row AS HGroupLayout
row = HGroupLayoutCreate(H_HORIZONTAL, 4)
CALL HTwoDimensionalLayoutSetInsets(row.handle, 10, 10, 10, 10)
CALL HWindowSetLayout(w, row.handle)

DIM leftBtn AS HButton
leftBtn = HButtonCreate(0, 0, 0, 0, "leftbtn", "Left", 1111)
CALL HLayoutAddView(row.handle, leftBtn.handle)

DIM glue AS ANY PTR
glue = HSpaceLayoutItemCreateGlue()
CALL HLayoutAddItem(row.handle, glue)

DIM rightBtn AS HButton
rightBtn = HButtonCreate(0, 0, 0, 0, "rightbtn", "Right", 2222)
CALL HLayoutAddView(row.handle, rightBtn.handle)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(2000)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "space layout item test ok"
