' A minimal window: create, show, respond to a message, close cleanly.
' H_QUIT_ON_WINDOW_CLOSE makes the whole application quit once this
' (its only) window closes.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM gWindow AS HWindow

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    PRINT "window received what="
    PRINT HMessageWhat(msg)
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-WindowExample")

gWindow = HWindowCreate(100, 100, 400, 300, "eb-haiku window example", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(gWindow, @OnWindowMessage, 0)
CALL HWindowShow(gWindow)

CALL Sleep(2000)
CALL HWindowClose(gWindow)

CALL HApplicationRun(app)
CALL HApplicationFree(app)
