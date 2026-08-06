' Slice 2: a window with a button, a label, and a text field. Clicking
' the button is simulated via HButtonInvoke (BInvoker::Invoke - the
' same real Haiku API a real click uses, not a test-only hack, since
' simulating an actual mouse click isn't available over SSH) and
' verified two ways: (1) an independently-checkable side effect (a
' written file) confirming the message really reached the window's own
' MessageReceived callback, and (2) a visual check (the label's text
' changes) via an external screenshot while this program is still
' running - see scripts/haiku_verify.sh.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_BUTTON_CLICKED = 2222

DIM gWindow AS HWindow
DIM gLabel AS HStringView

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = WHAT_BUTTON_CLICKED THEN
        CALL HStringViewSetText(gLabel, "clicked!")
        CALL WriteFile("/boot/home/eb_haiku_slice2_test.txt", "button was clicked")
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-ControlsBasicsTest")

gWindow = HWindowCreate(100, 100, 420, 260, "eb-haiku controls test", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(gWindow, @OnWindowMessage, 0)

DIM btn AS HButton
btn = HButtonCreate(20, 20, 140, 50, "clickme", "Click Me", WHAT_BUTTON_CLICKED)
CALL HWindowAddChild(gWindow, btn.handle)

gLabel = HStringViewCreate(20, 70, 300, 90, "label", "not clicked yet")
CALL HWindowAddChild(gWindow, gLabel.handle)

DIM txt AS HTextControl
txt = HTextControlCreate(20, 110, 300, 140, "textfield", "Name:", "eBasic", 3333)
CALL HWindowAddChild(gWindow, txt.handle)

CALL HWindowShow(gWindow)

' Confirm the initial text round-trips before simulating the click.
PRINT HStringViewGetText(gLabel)
PRINT HTextControlGetText(txt)

' HButtonSetLabel/GetLabel and HControlSetEnabled/IsEnabled - real
' BControl/BButton API, generic across both stock controls.
PRINT HButtonGetLabel(btn)
CALL HButtonSetLabel(btn, "Relabeled")
PRINT HButtonGetLabel(btn)

PRINT HControlIsEnabled(btn.handle)
CALL HControlSetEnabled(btn.handle, 0)
PRINT HControlIsEnabled(btn.handle)
CALL HControlSetEnabled(btn.handle, 1)
PRINT HControlIsEnabled(btn.handle)

PRINT HControlIsEnabled(txt.handle)
CALL HControlSetEnabled(txt.handle, 0)
PRINT HControlIsEnabled(txt.handle)
CALL HControlSetEnabled(txt.handle, 1)

CALL Sleep(1000) ' visible before the click, for an external screenshot
CALL HButtonInvoke(btn)
CALL Sleep(1000) ' visible after the click, for a second external screenshot

PRINT HStringViewGetText(gLabel)
PRINT FileExists("/boot/home/eb_haiku_slice2_test.txt")

CALL HWindowClose(gWindow)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

CALL Kill("/boot/home/eb_haiku_slice2_test.txt")

PRINT "controls basics test ok"
