' Idiomatic layer: BRoster - find/launch/activate other running Haiku
' apps, via the shared `be_roster` singleton (exposed the same way
' BTranslatorRoster::Default() already is). Never freed by this package
' (owned by the Application Kit itself).

#include once "raw/haiku_shim.bas"
#include once "message.bas"
#include once "path.bas"

TYPE HRoster
    handle AS ANY PTR
END TYPE

FUNCTION HRosterDefault() AS HRoster
    DIM r AS HRoster
    r.handle = eb_haiku_roster_default()
    HRosterDefault = r
END FUNCTION

''' Whether an app with this MIME signature (e.g.
''' "application/x-vnd.Haiku-Tracker") is currently running.
FUNCTION HRosterIsRunning(BYVAL r AS HRoster, signature AS ZSTRING) AS INTEGER
    HRosterIsRunning = eb_haiku_roster_is_running(r.handle, signature)
END FUNCTION

''' The team_id of a running app with this signature, or <= 0 if not
''' running.
FUNCTION HRosterTeamFor(BYVAL r AS HRoster, signature AS ZSTRING) AS INTEGER
    HRosterTeamFor = eb_haiku_roster_team_for(r.handle, signature)
END FUNCTION

''' Launches the app registered for `signature`, filling `outTeam` with
''' its new team_id. Returns a status code (0 = success).
FUNCTION HRosterLaunch(BYVAL r AS HRoster, signature AS ZSTRING, BYREF outTeam AS INTEGER) AS INTEGER
    DIM team AS INTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_roster_launch(r.handle, signature, @team)
    outTeam = team
    HRosterLaunch = rc
END FUNCTION

''' Brings a running app (by team_id, from HRosterTeamFor/HRosterLaunch)
''' to the front. Returns a status code (0 = success).
FUNCTION HRosterActivateApp(BYVAL r AS HRoster, BYVAL team AS INTEGER) AS INTEGER
    HRosterActivateApp = eb_haiku_roster_activate_app(r.handle, team)
END FUNCTION

''' Sends `message` to every running app. Returns a status code.
FUNCTION HRosterBroadcast(BYVAL r AS HRoster, BYVAL message AS HMessage) AS INTEGER
    HRosterBroadcast = eb_haiku_roster_broadcast(r.handle, message.handle)
END FUNCTION

''' Fills outTeam/outThread/outFlags and outPath (from HPathCreateEmpty
''' - the app's own real executable path) for the app registered under
''' `signature`. Returns a status code (0 = success).
FUNCTION HRosterGetAppInfo(BYVAL r AS HRoster, signature AS ZSTRING, BYREF outTeam AS INTEGER, BYREF outThread AS INTEGER, BYREF outFlags AS UINTEGER, BYVAL outPath AS HPath) AS INTEGER
    DIM team AS INTEGER
    DIM thread AS INTEGER
    DIM flags AS UINTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_roster_get_app_info(r.handle, signature, @team, @thread, @flags, outPath.handle)
    outTeam = team
    outThread = thread
    outFlags = flags
    HRosterGetAppInfo = rc
END FUNCTION

''' Like HRosterGetAppInfo, but looked up by a running team_id (e.g.
''' from HRosterTeamFor) instead of its signature - also fills
''' `outSignature` (caller-supplied, `sigBufSize` bytes, NOT null-
''' terminated automatically, matching this package's own established
''' buffer-out convention) with the app's own real registered
''' signature. Returns a status code (0 = success).
FUNCTION HRosterGetRunningAppInfo(BYVAL r AS HRoster, BYVAL team AS INTEGER, BYREF outThread AS INTEGER, BYREF outFlags AS UINTEGER, BYVAL outPath AS HPath, BYVAL outSignature AS ANY PTR, BYVAL sigBufSize AS INTEGER) AS INTEGER
    DIM thread AS INTEGER
    DIM flags AS UINTEGER
    DIM rc AS INTEGER
    rc = eb_haiku_roster_get_running_app_info(r.handle, team, @thread, @flags, outPath.handle, outSignature, sigBufSize)
    outThread = thread
    outFlags = flags
    HRosterGetRunningAppInfo = rc
END FUNCTION

''' Fills `outPath` with the real executable path of the app registered
''' to handle `mimeType`. Returns a status code (0 = success).
FUNCTION HRosterFindApp(BYVAL r AS HRoster, mimeType AS ZSTRING, BYVAL outPath AS HPath) AS INTEGER
    HRosterFindApp = eb_haiku_roster_find_app(r.handle, mimeType, outPath.handle)
END FUNCTION

''' Fills `outMessage` (an existing HMessageCreate result) with the
''' real, system-wide list of recently opened documents, as a repeated
''' entry_ref field named "refs" - read via HMessageCountItems/
''' FindRefAt (message.bas, filling an HPath each). `fileType`/
''' `signature` are optional filters - pass "" for "no filter" (real
''' Haiku's own NULL default; eBasic's ZSTRING can't represent NULL
''' directly, so an empty string is translated to NULL internally).
SUB HRosterGetRecentDocuments(BYVAL r AS HRoster, BYVAL outMessage AS HMessage, BYVAL maxCount AS INTEGER, fileType AS ZSTRING, signature AS ZSTRING)
    CALL eb_haiku_roster_get_recent_documents(r.handle, outMessage.handle, maxCount, fileType, signature)
END SUB

''' Like HRosterGetRecentDocuments, but recently opened folders -
''' `signature` is likewise an optional filter ("" for none).
SUB HRosterGetRecentFolders(BYVAL r AS HRoster, BYVAL outMessage AS HMessage, BYVAL maxCount AS INTEGER, signature AS ZSTRING)
    CALL eb_haiku_roster_get_recent_folders(r.handle, outMessage.handle, maxCount, signature)
END SUB

''' Fills `outMessage` with the real, system-wide list of recently
''' launched apps, as a repeated entry_ref field named "refs".
SUB HRosterGetRecentApps(BYVAL r AS HRoster, BYVAL outMessage AS HMessage, BYVAL maxCount AS INTEGER)
    CALL eb_haiku_roster_get_recent_apps(r.handle, outMessage.handle, maxCount)
END SUB
