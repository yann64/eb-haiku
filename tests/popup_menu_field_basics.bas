' Interface Kit: BPopUpMenu + BMenuField - closes the two real gaps left
' from v0.6.0's own menu work (context menus + a combined menu/text-
' field control). BPopUpMenu IS-A BMenu (like BMenuBar already is) -
' reuses the plain HMenu type and its existing HMenuAddItem/AddSubmenu/
' AddSeparatorItem functions directly.
'
' IMPORTANT, confirmed by direct reproduction: real interactive item
' *selection* via BPopUpMenu::Go() needs a human mouse click - not
' triggerable over SSH (the same real limitation as HPrintJobConfigJob).
' This test therefore only drives the async=1 path (returns promptly
' with no selection), verifying it runs/renders without crashing or
' hanging - not real click-driven selection.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_POPUP_ITEM = 4444
CONST WHAT_FIELD_ITEM_A = 5555
CONST WHAT_FIELD_ITEM_B = 6666

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-PopupMenuFieldTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku popup/menufield test", H_QUIT_ON_WINDOW_CLOSE)

' ---- Part 1: BPopUpMenu ----

DIM popup AS HMenu
popup = HPopUpMenuCreate("popup")

DIM popupMsg AS HMessage
popupMsg = HMessageCreate(WHAT_POPUP_ITEM)
DIM popupItem AS HMenuItem
popupItem = HMenuItemCreate("Popup Item", popupMsg)
CALL HMenuAddItem(popup, popupItem)

CALL HWindowShow(w)
CALL Sleep(500)

' async=1: returns immediately with a null handle (no real click to
' pick anything) - confirms Go() itself is safe to call, not a real
' end-to-end selection test.
DIM picked AS HMenuItem
picked = HPopUpMenuGo(popup, 150, 150, 0, 0, 1)
PRINT "popup Go(async) returned handle=", picked.handle
IF picked.handle <> 0 THEN
    PRINT "FAIL: async Go() should return a null handle immediately"
    CALL ExitProcess(1)
END IF
PRINT "BPopUpMenu Go(async) ran ok"

' ---- Part 2: BMenuField ----

DIM fieldMenu AS HMenu
fieldMenu = HMenuCreate("field menu")

DIM itemAMsg AS HMessage
itemAMsg = HMessageCreate(WHAT_FIELD_ITEM_A)
DIM itemA AS HMenuItem
itemA = HMenuItemCreate("Item A", itemAMsg)
CALL HMenuAddItem(fieldMenu, itemA)

DIM field AS HMenuField
field = HMenuFieldCreate(20, 20, 300, 50, "field", "Choose:", fieldMenu)
CALL HWindowAddChild(w, field.handle)

' HMenuFieldMenu should return the SAME underlying BMenu, not a copy -
' confirmed by adding a second item through it and checking the field
' still wraps one coherent menu (no crash, same handle back).
DIM wrappedMenu AS HMenu
wrappedMenu = HMenuFieldMenu(field)
IF wrappedMenu.handle <> fieldMenu.handle THEN
    PRINT "FAIL: HMenuFieldMenu should return the same menu handle passed to HMenuFieldCreate"
    CALL ExitProcess(1)
END IF

DIM itemBMsg AS HMessage
itemBMsg = HMessageCreate(WHAT_FIELD_ITEM_B)
DIM itemB AS HMenuItem
itemB = HMenuItemCreate("Item B", itemBMsg)
CALL HMenuAddItem(wrappedMenu, itemB)
PRINT "HMenuFieldMenu round-trip and post-creation AddItem ok"

CALL Sleep(1000) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "popup menu / menu field basics test ok"
