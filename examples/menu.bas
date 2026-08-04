' BMenuBar/BMenu/BMenuItem - a real "File > Open, File > Quit" menu. A
' menu bar must be hosted in a real layout (its own constructor takes
' no BRect frame at all - see HMenuBarCreate's own doc comment in
' src/menu.bas), with the menu bar as the layout's first item so it
' gets its own natural height and the rest of the window is free for
' real content below it.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_OPEN = 1111
CONST WHAT_QUIT_ITEM = 2222

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    DIM what AS UINTEGER
    what = HMessageWhat(msg)
    IF what = WHAT_OPEN THEN
        PRINT "Open selected"
    END IF
    IF what = WHAT_QUIT_ITEM THEN
        PRINT "Quit selected"
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MenuExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 400, 300, "eb-haiku menu example", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)

DIM layout AS HGroupLayout
layout = HGroupLayoutCreate(H_VERTICAL, 0)
CALL HWindowSetLayout(w, layout.handle)

DIM menuBar AS HMenu
menuBar = HMenuBarCreate("menu bar")

DIM fileMenu AS HMenu
fileMenu = HMenuCreate("File")

DIM openItem AS HMenuItem
openItem = HMenuItemCreate("Open", HMessageCreate(WHAT_OPEN))
CALL HMenuAddItem(fileMenu, openItem)
CALL HMenuAddSeparatorItem(fileMenu)
DIM quitItem AS HMenuItem
quitItem = HMenuItemCreate("Quit", HMessageCreate(WHAT_QUIT_ITEM))
CALL HMenuAddItem(fileMenu, quitItem)

CALL HMenuAddSubmenu(menuBar, fileMenu)
CALL HGroupLayoutAddView(layout, menuBar.handle)

DIM content AS HStringView
content = HStringViewCreate(0, 0, 0, 0, "content", "Try File > Open / File > Quit")
CALL HGroupLayoutAddView(layout, content.handle)

CALL HWindowShow(w)
CALL Sleep(1000)

' A real click isn't triggerable over SSH - drive both items end to
' end exactly as a click would, via the safe Messenger-based invoke.
CALL HMenuItemInvokeViaMessenger(openItem)
CALL Sleep(300)
CALL HMenuItemInvokeViaMessenger(quitItem)
CALL Sleep(1500)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
