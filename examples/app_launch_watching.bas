' BRoster::StartWatching - real system-wide app launch/quit
' notifications. Confirmed by direct reproduction: these are only
' delivered while this program's own message loop (HApplicationRun) is
' actively pumping - here a background thread launches and quits
' StyledEdit AFTER Run() has started, exactly as a real interactive
' trigger (another app launching) would arrive.

#include once "../src/lib.bas"

CONST STYLED_EDIT_SIGNATURE = "application/x-vnd.Haiku-StyledEdit"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-AppLaunchWatchingExample")

SUB OnRosterMessage(userData AS ANY PTR, messageHandle AS ANY PTR)
    DIM msg AS HMessage
    msg.handle = messageHandle
    DIM what AS UINTEGER
    what = HMessageWhat(msg)
    IF what = H_SOME_APP_LAUNCHED THEN
        PRINT "app launched: ", HMessageFindString(msg, "be:signature")
    END IF
    IF what = H_SOME_APP_QUIT THEN
        PRINT "app quit: ", HMessageFindString(msg, "be:signature")
    END IF
END SUB

DIM roster AS HRoster
roster = HRosterDefault()

DIM watcher AS HWatcher
watcher = HWatcherCreate()
CALL HWatcherSetMessageReceivedCallback(watcher, @OnRosterMessage, 0)
CALL HRosterStartWatching(roster, watcher, H_REQUEST_LAUNCHED OR H_REQUEST_QUIT)

FUNCTION TriggerThreadFunc(data AS ANY PTR) AS INTEGER
    DIM team AS INTEGER
    CALL HSnooze(300000)
    CALL HRosterLaunch(roster, STYLED_EDIT_SIGNATURE, team)
    CALL HSnooze(1000000)
    CALL Shell("quit " & STYLED_EDIT_SIGNATURE)
    CALL HSnooze(500000)
    CALL HApplicationQuit(app)
    TriggerThreadFunc = 0
END FUNCTION

DIM t AS INTEGER
t = HSpawnThread(@TriggerThreadFunc, "eb-haiku-app-watch-trigger", H_NORMAL_PRIORITY, 0)
CALL HResumeThread(t)

CALL HApplicationRun(app)

DIM tv AS INTEGER
CALL HWaitForThread(t, tv)

' Free anything referencing be_app before HApplicationFree (see
' HWatcherFree's own doc comment).
CALL HRosterStopWatching(roster, watcher)
CALL HWatcherFree(watcher)
CALL HApplicationFree(app)
