' Interface Kit: BPrintJob. IMPORTANT, confirmed by direct
' reproduction (a standalone C++ probe, before writing this test):
' HPrintJobConfigJob/ConfigPage show a real, interactive dialog and
' hang indefinitely waiting for a human to click through it - not
' triggerable over SSH, the same real limitation already documented
' throughout this package for mouse clicks. This test therefore
' deliberately never calls them, and verifies everything that's safely
' testable headlessly instead: creation, the real (if unconfigured -
' PaperRect/PrintableRect are degenerate without ConfigJob, confirmed
' via the same probe) accessors, and that BeginJob/CanContinue/
' CancelJob run without crashing or hanging.

#include once "../src/lib.bas"

DIM job AS HPrintJob
job = HPrintJobCreate("eb-haiku-printjob-test")

DIM callbackFired AS INTEGER
callbackFired = 0

SUB OnDrawView(userData AS ANY PTR, view AS ANY PTR, rectLeft AS SINGLE, rectTop AS SINGLE, rectRight AS SINGLE, rectBottom AS SINGLE, whereX AS SINGLE, whereY AS SINGLE)
    callbackFired = 1
END SUB

CALL HPrintJobSetDrawViewCallback(job, @OnDrawView, 0)

' Without HPrintJobConfigJob (deliberately skipped - see this file's
' own top comment), PaperRect/PrintableRect are real but degenerate
' (an empty/invalid rect) - confirmed via a standalone probe, not
' assumed. Just confirm the calls themselves run without crashing.
DIM pLeft AS SINGLE
DIM pTop AS SINGLE
DIM pRight AS SINGLE
DIM pBottom AS SINGLE
CALL HPrintJobPaperRect(job, pLeft, pTop, pRight, pBottom)
PRINT "paper rect (unconfigured)=", pLeft, ",", pTop, ",", pRight, ",", pBottom

CALL HPrintJobPrintableRect(job, pLeft, pTop, pRight, pBottom)
PRINT "printable rect (unconfigured)=", pLeft, ",", pTop, ",", pRight, ",", pBottom

DIM xDPI AS INTEGER
DIM yDPI AS INTEGER
CALL HPrintJobGetResolution(job, xDPI, yDPI)
PRINT "resolution=", xDPI, "x", yDPI

PRINT "printer type=", HPrintJobPrinterType(job)

' Settings() - a real, borrowed BMessage (never HMessageFree it - see
' HPrintJobSettings's own doc comment). Confirmed by direct
' reproduction: without a real ConfigJob/ConfigPage, Settings() legitimately
' returns a null handle (real Haiku behavior, not a bug - same
' unconfigured-degenerate-state category as PaperRect/PrintableRect
' above). HPrintJobSetSettings is deliberately NEVER called here -
' confirmed by direct reproduction (a standalone C++ probe) that
' calling it with anything other than a message from a real, configured
' job can HANG INDEFINITELY, the same real limitation category as
' ConfigJob/ConfigPage's own interactive dialogs.
DIM settings AS HMessage
settings = HPrintJobSettings(job)
IF settings.handle <> 0 THEN
    PRINT "FAIL: HPrintJobSettings should be null without real ConfigJob/ConfigPage"
    CALL ExitProcess(1)
END IF
PRINT "Settings() correctly null without configuration ok"

DIM arbitrary AS HMessage
arbitrary = HMessageCreate(1414743380) ' 'TEST'
IF HPrintJobIsSettingsMessageValid(job, arbitrary) <> 0 THEN
    PRINT "FAIL: an arbitrary message should not be a valid settings archive"
    CALL ExitProcess(1)
END IF
CALL HMessageFree(arbitrary)
PRINT "IsSettingsMessageValid correctly rejects an arbitrary message ok"

CALL HPrintJobBeginJob(job)
PRINT "BeginJob ran ok"

' Without real page/printer configuration, CanContinue should
' correctly report false (no valid job to spool) - confirmed via the
' same standalone probe, not assumed.
IF HPrintJobCanContinue(job) <> 0 THEN
    PRINT "FAIL: CanContinue should be false without real ConfigJob/ConfigPage"
    CALL ExitProcess(1)
END IF
PRINT "CanContinue correctly false without configuration ok"

CALL HPrintJobCancelJob(job)
PRINT "CancelJob ran ok"

CALL HPrintJobFree(job)

PRINT "printjob basics test ok"
