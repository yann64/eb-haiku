' BRoster (find/launch/activate other running apps) + BClipboard
' (system copy/paste). Requires an HApplication to exist first (not
' run - just constructed) - BClipboard hangs indefinitely otherwise,
' confirmed by direct reproduction - see clipboard.bas's own top
' comment.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-RosterClipboardExample")

DIM roster AS HRoster
roster = HRosterDefault()

CONST TRACKER_SIGNATURE = "application/x-vnd.Be-TRAK"
IF HRosterIsRunning(roster, TRACKER_SIGNATURE) = 1 THEN
    PRINT "Tracker is running, team=", HRosterTeamFor(roster, TRACKER_SIGNATURE)
END IF

DIM clip AS HClipboard
clip = HClipboardDefault()

CALL HClipboardSetText(clip, "hello from eb-haiku")

DIM buf(255) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)
DIM n AS INTEGER
n = HClipboardGetText(clip, bufPtr, 256)
IF n >= 0 THEN
    buf(n) = 0
    DIM z AS ZSTRING
    z = bufPtr
    DIM s AS STRING
    s = z
    PRINT "clipboard now contains: ", s
END IF

CALL HApplicationFree(app)
