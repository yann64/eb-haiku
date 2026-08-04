' BView::DragMessage - drag a real BMessage from one view to another.
' Starting a drag needs a real, currently-held-down mouse button
' (confirmed by direct reproduction: calling HViewDragMessage outside a
' real MouseDown blocks indefinitely, the same "not triggerable over
' SSH" limitation as HPopUpMenuGo/HPrintJobConfigJob) - run this
' interactively on a real Haiku desktop session and actually drag from
' the left box to the right one.

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_DRAG_ITEM = 3344

SUB OnSourceMouseDown(userData AS ANY PTR, x AS SINGLE, y AS SINGLE)
    DIM msg AS HMessage
    msg = HMessageCreate(WHAT_DRAG_ITEM)
    CALL HViewDragMessage(userData, msg.handle, x, y, x + 60, y + 30)
END SUB

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWasDropped(msg) = 1 THEN
        DIM dropX AS SINGLE
        DIM dropY AS SINGLE
        CALL HMessageDropPoint(msg, dropX, dropY)
        PRINT "dropped at screen point (", dropX, ",", dropY, ")"
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-DragDropExample")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 200, "eb-haiku drag and drop example", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)

DIM source AS HShimView
source = HShimViewCreate(20, 20, 160, 160, "source", 0, 0)
CALL HShimViewSetMouseDownCallback(source, @OnSourceMouseDown, source.handle)
CALL HWindowAddChild(w, source.handle)

DIM sourceLabel AS HStringView
sourceLabel = HStringViewCreate(25, 25, 155, 45, "sourceLabel", "Drag from here")
CALL HWindowAddChild(w, sourceLabel.handle)

DIM target AS HStringView
target = HStringViewCreate(220, 20, 400, 160, "target", "...to here")
CALL HWindowAddChild(w, target.handle)

CALL HWindowShow(w)
CALL Sleep(2000) ' interact with the window now, if running interactively

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)
