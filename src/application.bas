' Idiomatic layer: BApplication - lifecycle only, no subclassing.
'
' Without a subclassed MessageReceived override (Phase 2 - real GUI
' subclassing - is explicitly out of scope for this package), a running
' HApplication mostly just registers with the system and idles in its
' own message loop until quit. Still real and testable (registration,
' lifecycle), just not yet "build an interactive app."

#include once "raw/haiku_shim.bas"
#include once "handler.bas"

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

''' Requests the application's message loop to stop - safe to call from
''' any thread (posts a real B_QUIT_REQUESTED message rather than
''' calling Quit() directly, confirmed by direct reproduction: a direct
''' call fails with "you must Lock the application object" when called
''' from a thread other than the one that called HApplicationRun - the
''' same fix as HWindowClose's own).
SUB HApplicationQuit(BYVAL a AS HApplication)
    CALL eb_haiku_application_quit(a.handle)
END SUB

''' Frees an HApplication - call exactly once, after HApplicationRun has
''' returned.
SUB HApplicationFree(BYVAL a AS HApplication)
    CALL eb_haiku_application_destroy(a.handle)
END SUB

''' Attaches `h` to the application's own `BLooper` - the same real
''' mechanism `HWindowAddHandler` gives windows, needed here for a
''' widget-level `HHandler` created before any specific window is
''' known/attached (e.g. a button wired up before being added to a
''' layout).
SUB HApplicationAddHandler(BYVAL a AS HApplication, BYVAL h AS HHandler)
    CALL eb_haiku_application_add_handler(a.handle, h.handle)
END SUB
