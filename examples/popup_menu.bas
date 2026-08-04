' BPopUpMenu (context menu) + BMenuField (labeled dropdown field) - the
' two real gaps left from the original menu.bas example's own BMenuBar/
' BMenu/BMenuItem work. BPopUpMenu IS-A BMenu, so it reuses the same
' HMenu type/HMenuAddItem etc. already shown there.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-PopupMenuExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku popup menu example", H_QUIT_ON_WINDOW_CLOSE)

DIM popup AS HMenu
popup = HPopUpMenuCreate("size")
CALL HMenuAddItem(popup, HMenuItemCreate("Small", HMessageCreate(1)))
CALL HMenuAddItem(popup, HMenuItemCreate("Medium", HMessageCreate(2)))
CALL HMenuAddItem(popup, HMenuItemCreate("Large", HMessageCreate(3)))

DIM fieldMenu AS HMenu
fieldMenu = HMenuCreate("units")
CALL HMenuAddItem(fieldMenu, HMenuItemCreate("Inches", HMessageCreate(4)))
CALL HMenuAddItem(fieldMenu, HMenuItemCreate("Centimeters", HMessageCreate(5)))

DIM field AS HMenuField
field = HMenuFieldCreate(20, 20, 300, 50, "field", "Units:", fieldMenu)
CALL HWindowAddChild(w, field.handle)

DIM label AS HStringView
label = HStringViewCreate(20, 70, 380, 90, "label", "Right-click anywhere below for a context menu")
CALL HWindowAddChild(w, label.handle)

CALL HWindowShow(w)
CALL Sleep(1000)

' A real interactive selection needs a real mouse click - not
' triggerable over SSH (same limitation as HPrintJobConfigJob). This
' example shows the popup at a fixed screen point with async=1, which
' displays it without blocking; run it interactively on a real Haiku
' desktop session to actually pick an item.
DIM picked AS HMenuItem
picked = HPopUpMenuGo(popup, 200, 150, 0, 0, 1)
CALL Sleep(2000)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
