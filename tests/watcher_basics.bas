' Storage Kit: HWatcher + real live BQuery/BVolumeRoster notifications -
' Haiku's own live-notification mechanism (BMessenger-based), used by
' nothing in this package before now. Verified with real concurrency
' correctness (a background thread creates a matching file while the
' query is live, confirming a real B_QUERY_UPDATE actually arrives),
' not just "the calls don't crash" - the same bar this package already
' set for BLocker/Kernel Kit concurrency.
'
' Predicate is on the real, always-indexed built-in "name" attribute
' (confirmed via the real `query` command-line tool before writing this
' test) - no custom index needed, and the match happens atomically at
' file creation, avoiding any ambiguity around attribute-write-
' triggered "started matching" events.

#include once "../src/lib.bas"

CONST DIR_PATH = "/boot/home/eb-haiku-watcher-live-test"
CONST MATCH_NAME = "live_match.txt"

DIM gApp AS HApplication
DIM gGotCreate AS INTEGER
gGotCreate = 0

SUB OnWatcherMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = H_QUERY_UPDATE THEN
        DIM opcode AS INTEGER
        opcode = HMessageFindInt32(msg, "opcode")
        IF opcode = H_ENTRY_CREATED THEN
            DIM nm AS STRING
            nm = HMessageFindString(msg, "name")
            PRINT "live query update: entry created, name=", nm
            IF nm = MATCH_NAME THEN
                gGotCreate = 1
            END IF
        END IF
    END IF
END SUB

' Clean up any leftover state from a previous failed run - IMPORTANT,
' confirmed by direct reproduction: a live query's B_QUERY_UPDATE only
' ever fires H_ENTRY_CREATED for a genuinely *new* entry, not for
' overwriting an already-existing one (which already matched the
' predicate before this query's own Fetch() started monitoring, and so
' generates no membership-change event at all) - a stale file left over
' from an interrupted prior run therefore silently swallows this test's
' own real signal, not a real binding bug.
CALL Kill(DIR_PATH & "/" & MATCH_NAME)
CALL RmDir(DIR_PATH)

DIM rc AS INTEGER
rc = MkDir(DIR_PATH)
DIM d AS HDirectory
d = HDirectoryCreate(DIR_PATH)
IF HDirectoryInitCheck(d) <> 0 THEN
    PRINT "FAIL: could not open the test directory"
    CALL ExitProcess(1)
END IF

DIM dirEntry AS HEntry
dirEntry = HEntryCreate(DIR_PATH)
DIM vol AS HVolume
vol = HVolumeCreateEmpty()
rc = HEntryGetVolume(dirEntry, vol)
IF rc <> 0 THEN
    PRINT "FAIL: HEntryGetVolume returned ", rc
    CALL ExitProcess(1)
END IF
CALL HEntryFree(dirEntry)

gApp = HApplicationCreate("application/x-vnd.EbHaiku-WatcherBasicsTest")

DIM watcher AS HWatcher
watcher = HWatcherCreate()
CALL HWatcherSetMessageReceivedCallback(watcher, @OnWatcherMessage, 0)

' ---- BVolumeRoster::StartWatching - verified only as far as safely
' possible before HApplicationRun (a real mount/unmount isn't exercised
' here for safety; only one BApplication may exist per process, so this
' reuses gApp rather than a second one) ----

DIM watcher2 AS HWatcher
watcher2 = HWatcherCreate()
DIM vr AS HVolumeRoster
vr = HVolumeRosterCreate()
rc = HVolumeRosterStartWatching(vr, watcher2)
IF rc <> 0 THEN
    PRINT "FAIL: HVolumeRosterStartWatching returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "HVolumeRosterStartWatching ran ok"
CALL HVolumeRosterStopWatching(vr)
CALL HVolumeRosterFree(vr)
CALL HWatcherFree(watcher2)

DIM q AS HQuery
q = HQueryCreate()
rc = HQuerySetVolume(q, vol)
IF rc <> 0 THEN
    PRINT "FAIL: HQuerySetVolume returned ", rc
    CALL ExitProcess(1)
END IF

rc = HQuerySetPredicate(q, "name==""" & MATCH_NAME & """")
IF rc <> 0 THEN
    PRINT "FAIL: HQuerySetPredicate returned ", rc
    CALL ExitProcess(1)
END IF

rc = HQuerySetTarget(q, watcher)
IF rc <> 0 THEN
    PRINT "FAIL: HQuerySetTarget returned ", rc
    CALL ExitProcess(1)
END IF
IF HQueryIsLive(q) = 0 THEN
    PRINT "FAIL: query should be live after HQuerySetTarget"
    CALL ExitProcess(1)
END IF

' IMPORTANT, confirmed by direct reproduction: HQuerySetTarget alone
' does NOT establish the real live monitor - HQueryFetch must still be
' called to actually register it with the kernel (see HQuerySetTarget's
' own doc comment in src/query.bas).
rc = HQueryFetch(q)
IF rc <> 0 THEN
    PRINT "FAIL: HQueryFetch returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "live query set up ok"

FUNCTION WriterThreadFunc(data AS ANY PTR) AS INTEGER
    CALL HSnooze(300000) ' 300ms - long enough for the query to be genuinely live first
    CALL WriteFile(DIR_PATH & "/" & MATCH_NAME, "hello")
    CALL HSnooze(1000000) ' 1s - generous time for the real B_QUERY_UPDATE to be dispatched
    CALL HApplicationQuit(gApp)
    WriterThreadFunc = 0
END FUNCTION

DIM t AS INTEGER
t = HSpawnThread(@WriterThreadFunc, "eb-haiku-watcher-writer", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t)

CALL HApplicationRun(gApp)

DIM rv AS INTEGER
CALL HWaitForThread(t, rv)

' IMPORTANT: free anything that references be_app (HWatcherFree calls
' be_app->RemoveHandler internally) BEFORE HApplicationFree - freeing
' the BApplication first leaves be_app dangling, and a later
' HWatcherFree would then touch freed memory. Same reasoning as every
' other "free the dependent resource before the thing it depends on"
' convention in this package.
CALL HQueryFree(q)
CALL HWatcherFree(watcher)
CALL HApplicationFree(gApp)

IF gGotCreate <> 1 THEN
    PRINT "FAIL: never received a real B_QUERY_UPDATE for the created file"
    CALL ExitProcess(1)
END IF
PRINT "real live query update received ok"

CALL HVolumeFree(vol)
CALL HDirectoryFree(d)

CALL Kill(DIR_PATH & "/" & MATCH_NAME)
CALL RmDir(DIR_PATH)

PRINT "watcher basics test ok"
