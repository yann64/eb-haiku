' Interface Kit: drag-and-drop (HViewDragMessage/HMessageWasDropped/
' DropPoint). Real Haiku's own DragMessage() is synchronous and needs
' an actual mouse button held down to ever return - confirmed by direct
' reproduction that calling it outside a real MouseDown callback blocks
' indefinitely, the same "not triggerable over SSH" limitation already
' documented for HPrintJobConfigJob/HPopUpMenuGo. This test therefore
' never calls HViewDragMessage itself, verifying only the headlessly-
' safe message-side accessors - see examples/drag_and_drop.bas for a
' real, interactive two-view drag meant to be run from a real desktop
' session.

#include once "../src/lib.bas"

DIM plainMsg AS HMessage
plainMsg = HMessageCreate(4242)

IF HMessageWasDropped(plainMsg) <> 0 THEN
    PRINT "FAIL: a plain, never-dropped message should report WasDropped=false"
    CALL ExitProcess(1)
END IF
PRINT "HMessageWasDropped correctly false for an ordinary message ok"

' DropPoint on a never-dropped message is real Haiku's own undefined
' territory (no real drop ever happened) - just confirm the call itself
' runs without crashing, not asserting a specific value.
DIM dropX AS SINGLE
DIM dropY AS SINGLE
CALL HMessageDropPoint(plainMsg, dropX, dropY)
PRINT "HMessageDropPoint ran ok (values undefined for a non-dropped message)"

CALL HMessageFree(plainMsg)

PRINT "drag/drop basics test ok"
