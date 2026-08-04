' Slice 1: a window appears, stays visible briefly (long enough to
' screenshot from a parallel driver - see scripts/haiku_verify.sh),
' then closes itself cleanly via a real B_QUIT_REQUESTED message
' (HWindowClose), which - because the window was created with
' H_QUIT_ON_WINDOW_CLOSE - also quits the application, so
' HApplicationRun returns and the program exits normally.
'
' Self-contained (single process, no second driver process needed for
' the close-cleanly assertion itself): BWindow's own message loop
' thread already runs once the window is constructed (Show() only
' affects visibility, not whether its thread is processing messages),
' so posting the close message right after Show() and then blocking in
' HApplicationRun (which itself runs on this thread) still lets the
' window's own thread process the queued messages and quit in time.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576 ' interface/Window.h - confirmed on the real Haiku host, not guessed

DIM gWindow AS HWindow
DIM gMessageCount AS INTEGER
gMessageCount = 0

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    gMessageCount = gMessageCount + 1
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-WindowBasicsTest")

gWindow = HWindowCreate(100, 100, 400, 300, "eb-haiku test window", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(gWindow, @OnWindowMessage, 0)
CALL HWindowShow(gWindow)

CALL Sleep(2000) ' visible for 2 seconds - long enough for an external screenshot
CALL HWindowClose(gWindow)

CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "window basics test ok"
