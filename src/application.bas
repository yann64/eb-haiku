' Idiomatic layer: BApplication - lifecycle only, no subclassing.
'
' Without a subclassed MessageReceived override (Phase 2 - real GUI
' subclassing - is explicitly out of scope for this package), a running
' HApplication mostly just registers with the system and idles in its
' own message loop until quit. Still real and testable (registration,
' lifecycle), just not yet "build an interactive app."

#include once "raw/haiku_shim.bas"

TYPE HApplication
    handle AS ANY PTR
END TYPE

''' Creates (but does not run) an application with the given signature -
''' a MIME-type-shaped string Haiku uses to identify your app
''' (e.g. "application/x-vnd.YourName-YourApp").
FUNCTION HApplicationCreate(signature AS ZSTRING) AS HApplication
    DIM a AS HApplication
    a.handle = eb_haiku_application_create(signature)
    HApplicationCreate = a
END FUNCTION

''' Whether the signature was valid and registration succeeded (0 =
''' success).
FUNCTION HApplicationInitCheck(BYVAL a AS HApplication) AS INTEGER
    HApplicationInitCheck = eb_haiku_application_init_check(a.handle)
END FUNCTION

''' Runs the application's message loop - blocks the calling thread
''' until HApplicationQuit is called (typically from another thread,
''' since this call doesn't return until then).
FUNCTION HApplicationRun(BYVAL a AS HApplication) AS INTEGER
    HApplicationRun = eb_haiku_application_run(a.handle)
END FUNCTION

''' Requests the application's message loop to stop.
SUB HApplicationQuit(BYVAL a AS HApplication)
    CALL eb_haiku_application_quit(a.handle)
END SUB

''' Frees an HApplication - call exactly once, after HApplicationRun has
''' returned.
SUB HApplicationFree(BYVAL a AS HApplication)
    CALL eb_haiku_application_destroy(a.handle)
END SUB
