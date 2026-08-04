' Translation Kit step 2: BTranslationUtils::GetBitmap - load a real
' PNG from disk into a BBitmap, verified headlessly (Bounds/ColorSpace
' match the file's own known real dimensions - the Haiku logo artwork
' fixture, a fixed, known-shipped file). Visual DrawBitmap confirmation
' happens separately via examples/load_and_display_image.bas + a real
' screenshot (step 6) - this test only checks the decode itself.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-GetBitmapTest")

DIM f AS HFile
f = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(f) <> 0 THEN
    PRINT "FAIL: could not open fixture PNG"
    CALL ExitProcess(1)
END IF

DIM b AS HBitmap
b = HGetBitmap(f.handle)
IF b.handle = 0 THEN
    PRINT "FAIL: HGetBitmap returned a null handle"
    CALL ExitProcess(1)
END IF
PRINT "get bitmap ok"

DIM bLeft AS SINGLE
DIM bTop AS SINGLE
DIM bRight AS SINGLE
DIM bBottom AS SINGLE
CALL HBitmapGetBounds(b, bLeft, bTop, bRight, bBottom)
IF bRight <= 0 OR bBottom <= 0 THEN
    PRINT "FAIL: decoded bitmap has non-positive bounds"
    CALL ExitProcess(1)
END IF
PRINT "decoded bounds right=", bRight
PRINT "decoded bounds bottom=", bBottom

DIM cs AS UINTEGER
cs = HBitmapColorSpace(b)
PRINT "decoded color space=", cs

CALL HBitmapFree(b)
CALL HFileFree(f)
CALL HApplicationFree(app)

PRINT "get bitmap test ok"
