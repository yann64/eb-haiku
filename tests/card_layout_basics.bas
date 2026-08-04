' Step 4: BCardLayout shows exactly one child ("card") at a time - two
' pages here, switched by a button click (simulated via HButtonInvoke,
' the same safe click-simulation this package already uses for stock
' controls - see controls_basics.bas). The button lives outside the
' card area itself (a card layout only ever shows one child, so the
' button couldn't be a "card" too) - nested via HViewSetLayout, the
' same pattern as nested_layout_basics.bas. Verified visually via two
' external screenshots, before and after the click (see
' scripts/haiku_verify.sh).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576
CONST WHAT_NEXT_PAGE = 4444

DIM gCards AS HCardLayout

SUB OnWindowMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = WHAT_NEXT_PAGE THEN
        CALL HCardLayoutSetVisibleItem(gCards, 1)
    END IF
END SUB

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-CardLayoutTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 360, 220, "eb-haiku card layout test", H_QUIT_ON_WINDOW_CLOSE)
CALL HWindowSetMessageReceivedCallback(w, @OnWindowMessage, 0)

DIM outer AS HGroupLayout
outer = HGroupLayoutCreate(H_VERTICAL, 8)
CALL HWindowSetLayout(w, outer.handle)

DIM cardArea AS HView
cardArea = HViewCreate(0, 0, 0, 0, "cardArea", H_FOLLOW_ALL, 0)
gCards = HCardLayoutCreate()
CALL HViewSetLayout(cardArea.handle, gCards.handle)
CALL HLayoutAddView(outer.handle, cardArea.handle)

DIM page1 AS HStringView
page1 = HStringViewCreate(0, 0, 0, 0, "page1", "This is page 1")
CALL HLayoutAddView(gCards.handle, page1.handle)

DIM page2 AS HStringView
page2 = HStringViewCreate(0, 0, 0, 0, "page2", "This is page 2")
CALL HLayoutAddView(gCards.handle, page2.handle)

DIM nextBtn AS HButton
nextBtn = HButtonCreate(0, 0, 0, 0, "next", "Next", WHAT_NEXT_PAGE)
CALL HLayoutAddView(outer.handle, nextBtn.handle)

PRINT HCardLayoutVisibleIndex(gCards)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(2500) ' page 1 visible for an external screenshot

CALL HButtonInvoke(nextBtn)
CALL Sleep(2500) ' page 2 visible for a second external screenshot

PRINT HCardLayoutVisibleIndex(gCards)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "card layout test ok"
