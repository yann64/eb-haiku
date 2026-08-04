' Idiomatic layer: BRoster - find/launch/activate other running Haiku
' apps, via the shared `be_roster` singleton (exposed the same way
' BTranslatorRoster::Default() already is). Never freed by this package
' (owned by the Application Kit itself).

#include once "raw/haiku_shim.bas"
#include once "message.bas"

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
