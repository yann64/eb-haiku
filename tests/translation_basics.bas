' Translation Kit step 1: BFile + BBitmap basics (create/destroy/
' inspect) - the foundational pieces underneath the rest of the
' Translation Kit. A real HApplication is constructed first (not run) -
' Translation Kit functions hang indefinitely without one, see this
' package's own README "Threading" section.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-TranslationBasicsTest")

' A real, known-present file on any Haiku install - just exercising
' BFile itself here, not decoding it yet (that's step 2).
DIM f AS HFile
f = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(f) <> 0 THEN
    PRINT "FAIL: HFileInitCheck on a real, present file"
    CALL ExitProcess(1)
END IF
PRINT "file init check ok"
CALL HFileFree(f)

' A real file that shouldn't exist - InitCheck should report failure.
DIM missing AS HFile
missing = HFileCreate("/boot/home/this-file-does-not-exist-eb-haiku-test.bin", H_READ_ONLY)
IF HFileInitCheck(missing) = 0 THEN
    PRINT "FAIL: HFileInitCheck should fail for a missing file"
    CALL ExitProcess(1)
END IF
PRINT "missing file init check ok"
CALL HFileFree(missing)

' An empty bitmap of known bounds.
DIM b AS HBitmap
b = HBitmapCreate(0, 0, 63, 31, H_RGB32, 0)
IF HBitmapInitCheck(b) <> 0 THEN
    PRINT "FAIL: HBitmapInitCheck on a freshly created bitmap"
    CALL ExitProcess(1)
END IF

DIM bLeft AS SINGLE
DIM bTop AS SINGLE
DIM bRight AS SINGLE
DIM bBottom AS SINGLE
CALL HBitmapGetBounds(b, bLeft, bTop, bRight, bBottom)
IF bLeft <> 0 OR bTop <> 0 OR bRight <> 63 OR bBottom <> 31 THEN
    PRINT "FAIL: HBitmapGetBounds mismatch"
    PRINT bLeft
    PRINT bTop
    PRINT bRight
    PRINT bBottom
    CALL ExitProcess(1)
END IF
PRINT "bitmap bounds ok"

IF HBitmapColorSpace(b) <> H_RGB32 THEN
    PRINT "FAIL: HBitmapColorSpace mismatch"
    CALL ExitProcess(1)
END IF
PRINT "bitmap color space ok"

CALL HBitmapFree(b)
CALL HApplicationFree(app)

PRINT "translation basics test ok"
