' Interface Kit: BMenuBar/BMenu/BMenuItem - a real "File > Open, File >
' Quit" menu attached to a window via the existing HWindowAddChild (no
' separate function needed - a menu bar IS a menu IS a view). Verifies
' the real auto-target-to-window behavior: an item's message, once the
' menu is attached, is delivered to the *window's own* MessageReceived
' callback with no explicit SetTarget call - confirmed here, not
' assumed. HMenuItemInvokeViaMessenger drives this end to end exactly
' like a real click would, without needing real mouse hardware (not
' triggerable over SSH - see this package's own established note on
' drawing_basics.bas).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_OPEN = 1111
CONST WHAT_QUIT_ITEM = 2222

DIM gOpenReceived AS INTEGER
DIM gQuitItemReceived AS INTEGER
gOpenReceived = 0
gQuitItemReceived = 0

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    DIM what AS UINTEGER
    what = HMessageWhat(msg)
    IF what = WHAT_OPEN THEN
        gOpenReceived = 1
    END IF
    IF what = WHAT_QUIT_ITEM THEN
        gQuitItemReceived = 1
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MenuBasicsTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 400, 300, "eb-haiku menu test", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)

' A BMenuBar's own layout-kit-friendly constructor (the one this
' package's HMenuBarCreate uses) takes no BRect frame at all - it's
' designed to live inside a BLayout, which sizes it automatically
' (confirmed: attaching it as a plain AddChild with no layout renders
' it at zero size, invisible). A vertical BGroupLayout with the menu
' bar as its first item is the real, standard way to host one.
DIM layout AS HGroupLayout
layout = HGroupLayoutCreate(H_VERTICAL, 0)
CALL HWindowSetLayout(w, layout.handle)

DIM menuBar AS HMenu
menuBar = HMenuBarCreate("menu bar")

DIM fileMenu AS HMenu
fileMenu = HMenuCreate("File")

DIM openMsg AS HMessage
openMsg = HMessageCreate(WHAT_OPEN)
DIM openItem AS HMenuItem
openItem = HMenuItemCreate("Open", openMsg)
CALL HMenuAddItem(fileMenu, openItem)

CALL HMenuAddSeparatorItem(fileMenu)

DIM quitMsg AS HMessage
quitMsg = HMessageCreate(WHAT_QUIT_ITEM)
DIM quitItem AS HMenuItem
quitItem = HMenuItemCreate("Quit", quitMsg)
CALL HMenuAddItem(fileMenu, quitItem)

CALL HMenuAddSubmenu(menuBar, fileMenu)
CALL HGroupLayoutAddView(layout, menuBar.handle)

CALL HWindowShow(w)
CALL Sleep(1000) ' let the window/menu fully attach before invoking

' Drive both items end to end - confirms real auto-target-to-window
' delivery with no explicit SetTarget call.
CALL HMenuItemInvokeViaMessenger(openItem)
CALL Sleep(300)
CALL HMenuItemInvokeViaMessenger(quitItem)
CALL Sleep(300)

CALL HMenuItemSetEnabled(openItem, 0)
CALL HMenuItemSetMarked(quitItem, 1)

' ---- Radio-mode grouping: real Haiku unmarks siblings automatically
' when one item is marked, entirely internal - verified by reading the
' marked state back after each HMenuItemSetMarked call. IMPORTANT,
' confirmed by direct reproduction: constructing a new BMenu (a BView)
' after HApplicationFree has already destroyed the BApplication hangs
' indefinitely - the same "needs a live BApplication" gotcha family as
' GetBitmap/BClipboard::Lock, but here needing one to still exist
' rather than merely have existed once. Do all real menu/item
' construction before HApplicationFree, never after. ----

DIM radioMenu AS HMenu
radioMenu = HMenuCreate("Size")
CALL HMenuSetRadioMode(radioMenu, 1)
IF HMenuIsRadioMode(radioMenu) <> 1 THEN
    PRINT "FAIL: HMenuIsRadioMode should be true after SetRadioMode(1)"
    CALL ExitProcess(1)
END IF

DIM smallItem AS HMenuItem
smallItem = HMenuItemCreate("Small", HMessageCreate(3001))
CALL HMenuAddItem(radioMenu, smallItem)
DIM mediumItem AS HMenuItem
mediumItem = HMenuItemCreate("Medium", HMessageCreate(3002))
CALL HMenuAddItem(radioMenu, mediumItem)
DIM largeItem AS HMenuItem
largeItem = HMenuItemCreate("Large", HMessageCreate(3003))
CALL HMenuAddItem(radioMenu, largeItem)

CALL HMenuItemSetMarked(smallItem, 1)
IF HMenuItemIsMarked(smallItem) <> 1 THEN
    PRINT "FAIL: smallItem should be marked"
    CALL ExitProcess(1)
END IF

CALL HMenuItemSetMarked(mediumItem, 1)
IF HMenuItemIsMarked(mediumItem) <> 1 THEN
    PRINT "FAIL: mediumItem should be marked"
    CALL ExitProcess(1)
END IF
IF HMenuItemIsMarked(smallItem) <> 0 THEN
    PRINT "FAIL: radio mode should have unmarked smallItem when mediumItem was marked"
    CALL ExitProcess(1)
END IF
IF HMenuItemIsMarked(largeItem) <> 0 THEN
    PRINT "FAIL: largeItem should never have been marked"
    CALL ExitProcess(1)
END IF
PRINT "radio-mode grouping ok"

CALL Sleep(1500) ' visible for an external screenshot

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

IF gOpenReceived <> 1 THEN
    PRINT "FAIL: the window never received the Open item's message"
    CALL ExitProcess(1)
END IF
IF gQuitItemReceived <> 1 THEN
    PRINT "FAIL: the window never received the Quit item's message"
    CALL ExitProcess(1)
END IF
PRINT "menu item auto-target-to-window ok"

PRINT "menu basics test ok"
