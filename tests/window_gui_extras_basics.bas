' eb-gui prerequisite additions: window title/move/resize/enable/modal,
' plus the new ShimHandler/HTimer machinery - a genuinely per-object
' callback target (unlike real Haiku's own BMenuItem/BMessageRunner,
' which both deliver via a BMessage sent to a shared window by default).
' Every check below is a direct function call + printed result, no
' synthetic mouse/keyboard input - matching this package's own
' established discipline (real interactive input isn't reliably
' driveable over SSH).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-GuiExtrasTest")

DIM win AS HWindow
win = HWindowCreate(50, 50, 300, 200, "gui extras test", H_QUIT_ON_WINDOW_CLOSE)

' 1. Title/move/resize - no getters exist on this backend either
' (matching eb-gui's own contract, which has none for this backend
' shape), so "did not crash" is the bar here.
CALL HWindowSetTitle(win, "renamed window")
CALL HWindowMoveTo(win, 60, 60)
CALL HWindowResizeTo(win, 320, 220)
PRINT "title/move/resize did not crash"

' 2. Enable/disable - a real BButton child, toggled via the window-level
' recursive walk, confirmed by reading the button's own enabled state
' back (not just "did not crash").
DIM btn AS HButton
btn = HButtonCreate(10, 10, 110, 40, "btn", "Test", 0)
CALL HWindowAddChild(win, btn.handle)
PRINT "button enabled by default: ", HControlIsEnabled(btn.handle)
CALL HWindowSetEnabled(win, 0)
PRINT "button enabled after HWindowSetEnabled(0): ", HControlIsEnabled(btn.handle)
CALL HWindowSetEnabled(win, 1)
PRINT "button enabled after HWindowSetEnabled(1): ", HControlIsEnabled(btn.handle)

' 3. Modal - a second window made modal to the first, then cleared.
DIM childWin AS HWindow
childWin = HWindowCreate(400, 400, 200, 150, "modal child", 0)
CALL HWindowSetModal(childWin, win)
CALL HWindowClearModal(childWin, win)
PRINT "modal set/clear did not crash"

' 4. ShimHandler + HMenuItemSetTarget - a real per-action callback,
' independent of the window's own shared MessageReceived (menu_basics.bas
' already covers the DEFAULT auto-target-to-window path; this is the
' new, explicit-target path eb-gui's own GuiActionConnectTriggered
' needs).
DIM actionCount AS INTEGER
actionCount = 0

SUB OnAction(userData AS ANY PTR)
    actionCount = actionCount + 1
END SUB

DIM actionHandler AS HHandler
actionHandler = HHandlerCreate()
CALL HWindowAddHandler(win, actionHandler)
CALL HHandlerSetCallback(actionHandler, @OnAction, 0)

DIM layout AS HGroupLayout
layout = HGroupLayoutCreate(H_VERTICAL, 0)
CALL HWindowSetLayout(win, layout.handle)

DIM menuBar AS HMenu
menuBar = HMenuBarCreate("menu bar")
DIM fileMenu AS HMenu
fileMenu = HMenuCreate("File")
DIM actionMsg AS HMessage
actionMsg = HMessageCreate(9001)
DIM actionItem AS HMenuItem
actionItem = HMenuItemCreate("Test", actionMsg)
CALL HMenuAddItem(fileMenu, actionItem)
CALL HMenuItemSetTarget(actionItem, actionHandler)
CALL HMenuAddSubmenu(menuBar, fileMenu)
CALL HGroupLayoutAddView(layout, menuBar.handle)

CALL HWindowShow(win)
CALL Sleep(500) ' let the window/menu/handler fully attach first

PRINT "before action invoke: ", actionCount
CALL HMenuItemInvokeViaMessenger(actionItem)
CALL Sleep(300)
PRINT "after action invoke: ", actionCount

' 5. HTimer - a real per-timer callback via its own ShimHandler,
' driving a real HApplicationQuit from a single-shot tick (the same
' "does the whole run/quit loop actually work together" proof
' eb-gtk4/eb-qt6's own GuiTimer verification examples use).
DIM t AS HTimer
t = HTimerCreate(win)
CALL HTimerSetInterval(t, 300000) ' 300ms, in microseconds
CALL HTimerSetSingleShot(t, 1)
PRINT "timer active before start: ", HTimerIsActive(t)

SUB OnTimeout(userData AS ANY PTR)
    PRINT "timer fired - quitting"
    CALL HApplicationQuit(app)
END SUB
CALL HTimerConnectTimeout(t, @OnTimeout, 0)
CALL HTimerStart(t)
PRINT "timer active after start: ", HTimerIsActive(t)

CALL HApplicationRun(app)
PRINT "HApplicationRun returned - timer-driven quit worked"
CALL HTimerDestroy(t)
CALL HApplicationFree(app)

IF actionCount <> 1 THEN
    PRINT "FAIL: expected exactly one action invocation, got ", actionCount
    CALL ExitProcess(1)
END IF

PRINT "window gui extras basics test ok"
