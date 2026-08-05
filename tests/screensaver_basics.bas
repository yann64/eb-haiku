' Screen Saver Kit: automated headless test for the real dlopen/
' factory/virtual-dispatch round trip - see tests/native/
' screensaver_harness.cpp for the real C++ side that drives this .so.
' Built via `ebc --shared-lib` (not a plain executable, unlike every
' other tests/*.bas file in this package) - the whole program IS the
' real, dynamically loadable add-on Haiku's own screensaver daemon
' would `dlopen`, so only declarations may appear at the top level (the
' same restriction `--lib` mode already has).
'
' Deliberately #includes only screensaver.bas, NOT the whole aggregated
' lib.bas: a shared library must resolve every Shim* class's vtable/RTTI
' relocations *eagerly* at load time regardless of RTLD_LAZY (unlike
' ordinary lazy PLT function binding) - pulling in every other Kit's own
' Shim* subclass (and its own real Haiku library dependency - game/
' mail/midi2/...) for no reason made a real, confirmed-by-direct-
' reproduction `dlopen` failure ("Symbol not found") the first time
' this test was written against `../src/lib.bas`. A real screensaver
' add-on should equally never pull in Kits it doesn't use - see
' examples/screensaver_example.bas for the same discipline.

#include once "../src/screensaver.bas"

Extern "C"
    Function instantiate_screen_saver(BYVAL archive AS ANY PTR, BYVAL id AS INTEGER) AS ANY PTR
        DIM saver AS HScreenSaver
        saver = HScreenSaverCreate(archive, id)
        CALL HScreenSaverSetInitCheckCallback(saver, @MyInitCheck, 0)
        CALL HScreenSaverSetStartSaverCallback(saver, @MyStartSaver, 0)
        CALL HScreenSaverSetStopSaverCallback(saver, @MyStopSaver, 0)
        CALL HScreenSaverSetDrawCallback(saver, @MyDraw, 0)
        instantiate_screen_saver = saver.handle
    End Function
End Extern

FUNCTION MyInitCheck(userData AS ANY PTR) AS INTEGER
    PRINT "InitCheck called"
    MyInitCheck = 0
END FUNCTION

FUNCTION MyStartSaver(userData AS ANY PTR, view AS ANY PTR, preview AS INTEGER) AS INTEGER
    PRINT "StartSaver called, preview=", preview
    MyStartSaver = 0
END FUNCTION

SUB MyStopSaver(userData AS ANY PTR)
    PRINT "StopSaver called"
END SUB

SUB MyDraw(userData AS ANY PTR, view AS ANY PTR, frame AS INTEGER)
    PRINT "Draw called, frame=", frame
END SUB
