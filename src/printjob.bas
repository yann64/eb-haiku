' Idiomatic layer: BPrintJob - real printing. Via a real ShimPrintJob
' subclass (native/shim_interface.cpp) forwarding the virtual DrawView()
' to an eBasic callback, which draws using this package's own already-
' bound view-drawing primitives (HViewSetHighColor/FillRect/DrawString/
' DrawBitmap - view.bas).
'
' IMPORTANT, confirmed by direct reproduction: HPrintJobConfigJob/
' ConfigPage show a real, interactive Page Setup/Print dialog and block
' until a human clicks through it - not triggerable over SSH (the same
' real limitation already documented throughout this package for mouse
' clicks), so this package's own tests/examples can't drive them
' headlessly. The rest of the real API (BeginJob/SpoolPage/CommitJob/
' CanContinue/PaperRect/PrintableRect/PrinterType/GetResolution) is
' still real and useful for interactive use on a real desktop session.

#include once "raw/haiku_shim_interface.bas"
#include once "message.bas"

CONST H_BW_PRINTER = 0
CONST H_COLOR_PRINTER = 1

TYPE HPrintJob
    handle AS ANY PTR
END TYPE

FUNCTION HPrintJobCreate(name AS ZSTRING) AS HPrintJob
    DIM j AS HPrintJob
    j.handle = eb_haiku_print_job_create(name)
    HPrintJobCreate = j
END FUNCTION

''' `cb` must be a plain top-level bodied SUB taking (userData AS ANY
''' PTR, view AS ANY PTR, rectLeft AS SINGLE, rectTop AS SINGLE,
''' rectRight AS SINGLE, rectBottom AS SINGLE, whereX AS SINGLE, whereY
''' AS SINGLE), supplied via `@YourSubName`. Draw into `view` using the
''' same drawing primitives as a real window's own Draw callback
''' (HViewSetHighColor/FillRect/DrawString/DrawBitmap, view.bas) -
''' called once per page, from within HPrintJobSpoolPage.
SUB HPrintJobSetDrawViewCallback(BYVAL j AS HPrintJob, cb AS ANY PTR, userData AS ANY PTR)
    CALL eb_haiku_print_job_set_draw_view_callback(j.handle, cb, userData)
END SUB

SUB HPrintJobBeginJob(BYVAL j AS HPrintJob)
    CALL eb_haiku_print_job_begin_job(j.handle)
END SUB

SUB HPrintJobCommitJob(BYVAL j AS HPrintJob)
    CALL eb_haiku_print_job_commit_job(j.handle)
END SUB

''' Shows a real, interactive printer-selection dialog - see this
''' file's own top comment. Returns a status code (0 = success).
FUNCTION HPrintJobConfigJob(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobConfigJob = eb_haiku_print_job_config_job(j.handle)
END FUNCTION

SUB HPrintJobCancelJob(BYVAL j AS HPrintJob)
    CALL eb_haiku_print_job_cancel_job(j.handle)
END SUB

''' Shows a real, interactive page-setup dialog - see this file's own
''' top comment. Returns a status code (0 = success).
FUNCTION HPrintJobConfigPage(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobConfigPage = eb_haiku_print_job_config_page(j.handle)
END FUNCTION

''' Spools one page, triggering a real DrawView call via the registered
''' HPrintJobSetDrawViewCallback callback.
SUB HPrintJobSpoolPage(BYVAL j AS HPrintJob)
    CALL eb_haiku_print_job_spool_page(j.handle)
END SUB

''' Whether there's another page to spool - loop `WHILE
''' HPrintJobCanContinue(j) <> 0`.
FUNCTION HPrintJobCanContinue(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobCanContinue = eb_haiku_print_job_can_continue(j.handle)
END FUNCTION

''' Fills the 4 BYREF out-params with the real, full paper size.
SUB HPrintJobPaperRect(BYVAL j AS HPrintJob, BYREF outLeft AS SINGLE, BYREF outTop AS SINGLE, BYREF outRight AS SINGLE, BYREF outBottom AS SINGLE)
    DIM buf(3) AS SINGLE
    CALL eb_haiku_print_job_paper_rect(j.handle, @buf(0), @buf(1), @buf(2), @buf(3))
    outLeft = buf(0)
    outTop = buf(1)
    outRight = buf(2)
    outBottom = buf(3)
END SUB

''' Fills the 4 BYREF out-params with the real printable area (inside
''' the printer's own margins).
SUB HPrintJobPrintableRect(BYVAL j AS HPrintJob, BYREF outLeft AS SINGLE, BYREF outTop AS SINGLE, BYREF outRight AS SINGLE, BYREF outBottom AS SINGLE)
    DIM buf(3) AS SINGLE
    CALL eb_haiku_print_job_printable_rect(j.handle, @buf(0), @buf(1), @buf(2), @buf(3))
    outLeft = buf(0)
    outTop = buf(1)
    outRight = buf(2)
    outBottom = buf(3)
END SUB

''' Fills the real horizontal/vertical resolution, in dots per inch.
SUB HPrintJobGetResolution(BYVAL j AS HPrintJob, BYREF outXDPI AS INTEGER, BYREF outYDPI AS INTEGER)
    DIM x AS INTEGER
    DIM y AS INTEGER
    CALL eb_haiku_print_job_get_resolution(j.handle, @x, @y)
    outXDPI = x
    outYDPI = y
END SUB

''' The job's own live settings archive - a *borrowed* HMessage, never
''' call HMessageFree on it (BPrintJob owns it). Read/write its fields
''' directly via HMessageFindString/AddString/etc. (message.bas) to
''' inspect or override what a real ConfigJob/ConfigPage dialog set.
''' IMPORTANT, confirmed by direct reproduction: returns a null handle
''' (handle = 0) until a real ConfigJob/ConfigPage call has established
''' a real printer/page choice - real Haiku behavior, not a bug (same
''' unconfigured-degenerate-state category as PaperRect/PrintableRect).
FUNCTION HPrintJobSettings(BYVAL j AS HPrintJob) AS HMessage
    DIM m AS HMessage
    m.handle = eb_haiku_print_job_settings(j.handle)
    HPrintJobSettings = m
END FUNCTION

''' Replaces the job's own settings archive with a caller-built one -
''' check HPrintJobIsSettingsMessageValid first. IMPORTANT, confirmed
''' by direct reproduction: calling this with a message that isn't a
''' real, validated settings archive (or without a real printer
''' connection established) can HANG INDEFINITELY - the same real
''' "needs a live print_server round-trip" category as
''' HPrintJobConfigJob/ConfigPage's own interactive dialogs, not
''' triggerable/safe over SSH. Only call this with a message that
''' itself came from a real HPrintJobSettings/ConfigJob call.
SUB HPrintJobSetSettings(BYVAL j AS HPrintJob, BYVAL archiveMessage AS HMessage)
    CALL eb_haiku_print_job_set_settings(j.handle, archiveMessage.handle)
END SUB

''' Whether `archiveMessage` has the real fields a BPrintJob settings
''' archive needs - safe to call with any message, unlike
''' HPrintJobSetSettings above.
FUNCTION HPrintJobIsSettingsMessageValid(BYVAL j AS HPrintJob, BYVAL archiveMessage AS HMessage) AS INTEGER
    HPrintJobIsSettingsMessageValid = eb_haiku_print_job_is_settings_message_valid(j.handle, archiveMessage.handle)
END FUNCTION

FUNCTION HPrintJobFirstPage(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobFirstPage = eb_haiku_print_job_first_page(j.handle)
END FUNCTION

FUNCTION HPrintJobLastPage(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobLastPage = eb_haiku_print_job_last_page(j.handle)
END FUNCTION

''' H_BW_PRINTER or H_COLOR_PRINTER.
FUNCTION HPrintJobPrinterType(BYVAL j AS HPrintJob) AS INTEGER
    HPrintJobPrinterType = eb_haiku_print_job_printer_type(j.handle)
END FUNCTION

''' Frees an HPrintJob - call exactly once.
SUB HPrintJobFree(BYVAL j AS HPrintJob)
    CALL eb_haiku_print_job_destroy(j.handle)
END SUB
