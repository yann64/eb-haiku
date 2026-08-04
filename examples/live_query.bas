' HWatcher + a real live BQuery - Haiku's own live-notification
' mechanism for filesystem queries. Watches a directory for a file
' matching a given name and prints a real notification the instant a
' background thread creates it.
'
' IMPORTANT, confirmed by direct reproduction: HQuerySetTarget alone
' does NOT establish the real live monitor - HQueryFetch must still be
' called afterward (see src/query.bas's own doc comment on
' HQuerySetTarget).

#include once "../src/lib.bas"

CONST DIR_PATH = "/boot/home/eb-haiku-live-query-example"
CONST WATCH_NAME = "trigger.txt"

DIM gApp AS HApplication

SUB OnWatcherMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    IF HMessageWhat(msg) = H_QUERY_UPDATE THEN
        DIM opcode AS INTEGER
        opcode = HMessageFindInt32(msg, "opcode")
        IF opcode = H_ENTRY_CREATED THEN
            PRINT "live update: entry created, name=", HMessageFindString(msg, "name")
        END IF
    END IF
END SUB

CALL Kill(DIR_PATH & "/" & WATCH_NAME)
CALL RmDir(DIR_PATH)
CALL MkDir(DIR_PATH)

DIM dirEntry AS HEntry
dirEntry = HEntryCreate(DIR_PATH)
DIM vol AS HVolume
vol = HVolumeCreateEmpty()
CALL HEntryGetVolume(dirEntry, vol)
CALL HEntryFree(dirEntry)

gApp = HApplicationCreate("application/x-vnd.EbHaiku-LiveQueryExample")

DIM watcher AS HWatcher
watcher = HWatcherCreate()
CALL HWatcherSetMessageReceivedCallback(watcher, @OnWatcherMessage, 0)

DIM q AS HQuery
q = HQueryCreate()
CALL HQuerySetVolume(q, vol)
CALL HQuerySetPredicate(q, "name==""" & WATCH_NAME & """")
CALL HQuerySetTarget(q, watcher)
CALL HQueryFetch(q)
PRINT "watching ", DIR_PATH, " for ", WATCH_NAME, "..."

FUNCTION TriggerThreadFunc(data AS ANY PTR) AS INTEGER
    CALL HSnooze(500000)
    PRINT "creating the file now..."
    CALL WriteFile(DIR_PATH & "/" & WATCH_NAME, "hello")
    CALL HSnooze(1000000)
    CALL HApplicationQuit(gApp)
    TriggerThreadFunc = 0
END FUNCTION

DIM t AS INTEGER
t = HSpawnThread(@TriggerThreadFunc, "eb-haiku-live-query-trigger", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t)

CALL HApplicationRun(gApp)

DIM rv AS INTEGER
CALL HWaitForThread(t, rv)

' Free anything referencing be_app BEFORE HApplicationFree - see
' HWatcherFree's own doc comment.
CALL HQueryFree(q)
CALL HWatcherFree(watcher)
CALL HApplicationFree(gApp)
CALL HVolumeFree(vol)

CALL Kill(DIR_PATH & "/" & WATCH_NAME)
CALL RmDir(DIR_PATH)
