' Application Kit: BRoster (find/launch/activate other running apps)
' and BClipboard (system copy/paste). BRoster verified against Tracker
' - a real, always-running system app on any live Haiku desktop session
' (confirmed real signature via `catattr BEOS:APP_SIG /boot/system/
' Tracker`, not guessed). BClipboard verified via a real round-trip
' using the correct real text convention (see clipboard.bas's own top
' comment) - confirmed via the real `clipboard` command-line tool's own
' debug dump before writing this test, not assumed.

#include once "../src/lib.bas"

CONST TRACKER_SIGNATURE = "application/x-vnd.Be-TRAK"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-RosterClipboardTest")

DIM roster AS HRoster
roster = HRosterDefault()

IF HRosterIsRunning(roster, TRACKER_SIGNATURE) <> 1 THEN
    PRINT "FAIL: Tracker should be running on a live desktop session"
    CALL ExitProcess(1)
END IF
PRINT "IsRunning ok"

DIM trackerTeam AS INTEGER
trackerTeam = HRosterTeamFor(roster, TRACKER_SIGNATURE)
IF trackerTeam <= 0 THEN
    PRINT "FAIL: TeamFor should return a real positive team_id for Tracker, got ", trackerTeam
    CALL ExitProcess(1)
END IF
PRINT "TeamFor ok, team=", trackerTeam

DIM rc AS INTEGER
rc = HRosterActivateApp(roster, trackerTeam)
IF rc <> 0 THEN
    PRINT "FAIL: ActivateApp on a real running team returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "ActivateApp ok"

' ---- BClipboard ----

DIM clip AS HClipboard
clip = HClipboardDefault()

CONST TEST_TEXT = "eb-haiku clipboard round-trip"
rc = HClipboardSetText(clip, TEST_TEXT)
IF rc <> 0 THEN
    PRINT "FAIL: HClipboardSetText returned ", rc
    CALL ExitProcess(1)
END IF

DIM buf(255) AS BYTE
DIM bufPtr AS ANY PTR
bufPtr = @buf(0)
DIM n AS INTEGER
n = HClipboardGetText(clip, bufPtr, 256)
IF n < 0 THEN
    PRINT "FAIL: HClipboardGetText returned ", n
    CALL ExitProcess(1)
END IF
buf(n) = 0
DIM textZ AS ZSTRING
textZ = bufPtr
DIM text AS STRING
text = textZ

PRINT "clipboard text=", text
IF text <> TEST_TEXT THEN
    PRINT "FAIL: clipboard round-trip mismatch"
    CALL ExitProcess(1)
END IF
PRINT "clipboard round-trip ok"

CALL HApplicationFree(app)

PRINT "roster/clipboard basics test ok"
