' Interface Kit - BPrintJob. Shows a real, interactive Page Setup/Print
' dialog (HPrintJobConfigJob/ConfigPage) - run this one from a real
' Haiku desktop session, not over a headless SSH connection (the
' dialogs can't be driven without a human - see printjob.bas's own top
' comment). Draws a filled rectangle and a line of text on one page
' using the same drawing primitives a real window's own Draw callback
' would use.

#include once "../src/lib.bas"

DIM job AS HPrintJob
job = HPrintJobCreate("eb-haiku print example")

SUB OnDrawView(userData AS ANY PTR, view AS ANY PTR, rectLeft AS SINGLE, rectTop AS SINGLE, rectRight AS SINGLE, rectBottom AS SINGLE, whereX AS SINGLE, whereY AS SINGLE)
    CALL HViewSetHighColor(view, 60, 120, 200)
    CALL HViewFillRect(view, 20, 20, 220, 100)
    CALL HViewSetHighColor(view, 0, 0, 0)
    CALL HViewDrawString(view, "Printed from eb-haiku", 20, 130)
END SUB

CALL HPrintJobSetDrawViewCallback(job, @OnDrawView, 0)

IF HPrintJobConfigJob(job) = 0 THEN
    IF HPrintJobConfigPage(job) = 0 THEN
        CALL HPrintJobBeginJob(job)
        DO WHILE HPrintJobCanContinue(job) <> 0
            CALL HPrintJobSpoolPage(job)
        LOOP
        CALL HPrintJobCommitJob(job)
        PRINT "print job committed"
    ELSE
        CALL HPrintJobCancelJob(job)
    END IF
ELSE
    PRINT "print setup cancelled"
END IF

CALL HPrintJobFree(job)
