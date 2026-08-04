' Translation Kit step 3: BTranslatorRoster::Translate + BBitmapStream -
' convert a real PNG to JPEG on disk, verified by loading the
' *converted* file back and confirming its own decoded dimensions still
' match the source (a real round-trip check, not just "the file
' exists").
'
' Real Haiku behavior, confirmed by direct reproduction (a standalone
' C++ probe hit the identical failure with no eBasic/shim involved
' before this was understood): most translators only declare a
' *compressed* format (e.g. 'JPEG') as an input on translators that
' write it, and 'bits' (the generic, uncompressed Be Bitmap format) as
' the other - they do NOT generally accept a *different* compressed
' format directly. Translate(source, ..., destination, 'JPEG') straight
' from a PNG file fails with B_NO_TRANSLATOR for exactly this reason -
' this is why BBitmapStream exists: decode with HGetBitmap first (any
' installed reader), then wrap the resulting HBitmap as a stream and
' Translate *that* ('bits') to the real target format. This matches
' how Haiku's own `translate` command-line tool behaves internally.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-ConvertTest")

DIM roster AS HTranslatorRoster
roster = HTranslatorRosterDefault()

DIM src AS HFile
src = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(src) <> 0 THEN
    PRINT "FAIL: could not open source PNG"
    CALL ExitProcess(1)
END IF

DIM decoded AS HBitmap
decoded = HGetBitmap(src.handle)
IF decoded.handle = 0 THEN
    PRINT "FAIL: could not decode source PNG"
    CALL ExitProcess(1)
END IF
CALL HFileFree(src)

DIM stream AS HBitmapStream
stream = HBitmapStreamCreate(decoded) ' takes ownership of `decoded`

DIM dst AS HFile
dst = HFileCreate("/tmp/eb_haiku_translated.jpg", H_WRITE_ONLY OR H_CREATE_FILE OR H_ERASE_FILE)
IF HFileInitCheck(dst) <> 0 THEN
    PRINT "FAIL: could not create destination JPEG"
    CALL ExitProcess(1)
END IF

DIM rc AS INTEGER
rc = HTranslate(roster, stream.handle, dst.handle, H_JPEG_FORMAT)
IF rc <> 0 THEN
    PRINT "FAIL: HTranslate returned", rc
    CALL ExitProcess(1)
END IF
PRINT "translate ok"

CALL HBitmapStreamFree(stream) ' also frees the wrapped bitmap
CALL HFileFree(dst)

' Round-trip: load the converted JPEG back and check its own decoded
' bounds match the original PNG's known dimensions (350x131).
DIM reloaded AS HFile
reloaded = HFileCreate("/tmp/eb_haiku_translated.jpg", H_READ_ONLY)
IF HFileInitCheck(reloaded) <> 0 THEN
    PRINT "FAIL: could not reopen converted JPEG"
    CALL ExitProcess(1)
END IF

DIM b AS HBitmap
b = HGetBitmap(reloaded.handle)
IF b.handle = 0 THEN
    PRINT "FAIL: HGetBitmap on the converted JPEG returned a null handle"
    CALL ExitProcess(1)
END IF

DIM bLeft AS SINGLE
DIM bTop AS SINGLE
DIM bRight AS SINGLE
DIM bBottom AS SINGLE
CALL HBitmapGetBounds(b, bLeft, bTop, bRight, bBottom)
PRINT "round-trip bounds right=", bRight
PRINT "round-trip bounds bottom=", bBottom
IF bRight <> 350 OR bBottom <> 131 THEN
    PRINT "FAIL: round-trip dimensions do not match the source PNG"
    CALL ExitProcess(1)
END IF

CALL HBitmapFree(b)
CALL HFileFree(reloaded)
CALL HApplicationFree(app)

PRINT "convert test ok"
