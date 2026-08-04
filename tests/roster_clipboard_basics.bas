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

DIM gGotClipboardChanged AS INTEGER
gGotClipboardChanged = 0

SUB OnClipboardWatcherMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = H_CLIPBOARD_CHANGED THEN
        gGotClipboardChanged = 1
    END IF
END SUB

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

' ---- GetAppInfo/GetRunningAppInfo/FindApp ----

DIM infoTeam AS INTEGER
DIM infoThread AS INTEGER
DIM infoFlags AS UINTEGER
DIM infoPath AS HPath
infoPath = HPathCreateEmpty()
rc = HRosterGetAppInfo(roster, TRACKER_SIGNATURE, infoTeam, infoThread, infoFlags, infoPath)
IF rc <> 0 THEN
    PRINT "FAIL: HRosterGetAppInfo returned ", rc
    CALL ExitProcess(1)
END IF
IF infoTeam <> trackerTeam THEN
    PRINT "FAIL: GetAppInfo team mismatch, expected ", trackerTeam, " got ", infoTeam
    CALL ExitProcess(1)
END IF
PRINT "GetAppInfo ok, path=", HPathGet(infoPath)

DIM runThread AS INTEGER
DIM runFlags AS UINTEGER
DIM runPath AS HPath
runPath = HPathCreateEmpty()
DIM sigBuf(255) AS BYTE
DIM sigBufPtr AS ANY PTR
sigBufPtr = @sigBuf(0)
rc = HRosterGetRunningAppInfo(roster, trackerTeam, runThread, runFlags, runPath, sigBufPtr, 256)
IF rc <> 0 THEN
    PRINT "FAIL: HRosterGetRunningAppInfo returned ", rc
    CALL ExitProcess(1)
END IF
sigBuf(255) = 0
DIM sigZ AS ZSTRING
sigZ = sigBufPtr
DIM sigStr AS STRING
sigStr = sigZ
PRINT "GetRunningAppInfo ok, signature=", sigStr
IF sigStr <> TRACKER_SIGNATURE THEN
    PRINT "FAIL: expected signature ", TRACKER_SIGNATURE, ", got ", sigStr
    CALL ExitProcess(1)
END IF
CALL HPathFree(infoPath)
CALL HPathFree(runPath)

DIM foundAppPath AS HPath
foundAppPath = HPathCreateEmpty()
rc = HRosterFindApp(roster, "text/plain", foundAppPath)
IF rc <> 0 THEN
    PRINT "FAIL: HRosterFindApp returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "FindApp(text/plain) ok, path=", HPathGet(foundAppPath)
CALL HPathFree(foundAppPath)

' ---- Recent documents/folders/apps - real, system-wide history; not
' asserted to any specific content (depends on this desktop's own real
' usage history), just confirmed to run without crashing and to fill a
' real repeated entry_ref field ----

DIM recentApps AS HMessage
recentApps = HMessageCreate(0)
CALL HRosterGetRecentApps(roster, recentApps, 10)
DIM recentAppCount AS INTEGER
recentAppCount = HMessageCountItems(recentApps, "refs", 0)
' IMPORTANT, confirmed by direct reproduction: if this system has no
' real recent-app-launch history at all, GetRecentApps' own result
' message has no "refs" field whatsoever (only a "result" status field)
' - HMessageCountItems then legitimately returns a negative status code,
' not 0. A negative value here means "no history," not a bug.
IF recentAppCount < 0 THEN
    PRINT "recent app count=0 (no real recent-app history on this system)"
ELSE
    PRINT "recent app count=", recentAppCount
END IF
IF recentAppCount > 0 THEN
    DIM recentAppPath AS HPath
    recentAppPath = HPathCreateEmpty()
    rc = HMessageFindRefAt(recentApps, "refs", 0, recentAppPath)
    IF rc <> 0 THEN
        PRINT "FAIL: HMessageFindRefAt returned ", rc
        CALL ExitProcess(1)
    END IF
    PRINT "recent app[0]=", HPathGet(recentAppPath)
    CALL HPathFree(recentAppPath)
END IF
CALL HMessageFree(recentApps)

DIM recentDocs AS HMessage
recentDocs = HMessageCreate(0)
CALL HRosterGetRecentDocuments(roster, recentDocs, 10, "", "")
PRINT "recent document count=", HMessageCountItems(recentDocs, "refs", 0)
CALL HMessageFree(recentDocs)

DIM recentFolders AS HMessage
recentFolders = HMessageCreate(0)
CALL HRosterGetRecentFolders(roster, recentFolders, 10, "")
PRINT "recent folder count=", HMessageCountItems(recentFolders, "refs", 0)
CALL HMessageFree(recentFolders)
PRINT "GetRecentApps/Documents/Folders ran ok"

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

' ---- BClipboard::StartWatching - a real self-triggered test: start
' watching, then change the clipboard from a background thread while
' this program's own message loop (HApplicationRun) is pumping,
' confirming the watcher callback actually fires ----

DIM watcher AS HWatcher
watcher = HWatcherCreate()
CALL HWatcherSetMessageReceivedCallback(watcher, @OnClipboardWatcherMessage, 0)
rc = HClipboardStartWatching(clip, watcher)
IF rc <> 0 THEN
    PRINT "FAIL: HClipboardStartWatching returned ", rc
    CALL ExitProcess(1)
END IF

FUNCTION ClipboardWriterThreadFunc(data AS ANY PTR) AS INTEGER
    CALL HSnooze(300000)
    CALL HClipboardSetText(clip, "eb-haiku clipboard watch trigger")
    CALL HSnooze(500000)
    CALL HApplicationQuit(app)
    ClipboardWriterThreadFunc = 0
END FUNCTION

DIM wt AS INTEGER
wt = HSpawnThread(@ClipboardWriterThreadFunc, "eb-haiku-clip-writer", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(wt)

CALL HApplicationRun(app)

DIM wrv AS INTEGER
CALL HWaitForThread(wt, wrv)

' IMPORTANT: free anything referencing be_app (HClipboardStopWatching/
' HWatcherFree) BEFORE HApplicationFree - see HWatcherFree's own doc
' comment (confirmed by direct reproduction: freeing the BApplication
' first leaves be_app dangling).
CALL HClipboardStopWatching(clip, watcher)
CALL HWatcherFree(watcher)
CALL HApplicationFree(app)

IF gGotClipboardChanged <> 1 THEN
    PRINT "FAIL: never received a real B_CLIPBOARD_CHANGED notification"
    CALL ExitProcess(1)
END IF
PRINT "clipboard watching ok"

PRINT "roster/clipboard basics test ok"
