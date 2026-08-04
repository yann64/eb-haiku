' A button whose click updates a label - Haiku's own BControl/BInvoker
' pattern posts the button's "what" message to its window automatically
' once attached, so the window's own MessageReceived callback is the
' only callback surface a stock control needs (see this package's own
' README).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_BUTTON_CLICKED = 2222

DIM gLabel AS HStringView

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = WHAT_BUTTON_CLICKED THEN
        CALL HStringViewSetText(gLabel, "clicked!")
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-ButtonExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 320, 200, "eb-haiku button example", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)

DIM btn AS HButton
btn = HButtonCreate(20, 20, 140, 50, "clickme", "Click Me", WHAT_BUTTON_CLICKED)
CALL HWindowAddChild(w, btn.handle)

gLabel = HStringViewCreate(20, 70, 260, 90, "label", "not clicked yet")
CALL HWindowAddChild(w, gLabel.handle)

CALL HWindowShow(w)
CALL Sleep(3000)
CALL HWindowClose(w)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
