' Converts a real PNG to JPEG via BTranslatorRoster - decode with
' HGetBitmap, wrap the result with HBitmapStreamCreate, then HTranslate
' *that* ('bits') to the target format. Going straight from one
' compressed format to another in a single HTranslate call typically
' fails (most translators only accept their own format or the generic
' 'bits' format as input) - see HTranslate's own doc comment in
' src/translation.bas.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-ConvertExample")

DIM roster AS HTranslatorRoster
roster = HTranslatorRosterDefault()

DIM src AS HFile
src = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
IF HFileInitCheck(src) <> 0 THEN
    PRINT "could not open the source image"
    CALL ExitProcess(1)
END IF

DIM decoded AS HBitmap
decoded = HGetBitmap(src.handle)
CALL HFileFree(src)
IF decoded.handle = 0 THEN
    PRINT "could not decode the source image"
    CALL ExitProcess(1)
END IF

DIM stream AS HBitmapStream
stream = HBitmapStreamCreate(decoded) ' takes ownership of `decoded`

DIM dst AS HFile
dst = HFileCreate("/boot/home/eb-haiku-converted.jpg", H_WRITE_ONLY OR H_CREATE_FILE OR H_ERASE_FILE)
IF HFileInitCheck(dst) <> 0 THEN
    PRINT "could not create the destination file"
    CALL ExitProcess(1)
END IF

DIM rc AS INTEGER
rc = HTranslate(roster, stream.handle, dst.handle, H_JPEG_FORMAT)
CALL HBitmapStreamFree(stream) ' also frees the wrapped bitmap
CALL HFileFree(dst)

IF rc <> 0 THEN
    PRINT "conversion failed with status ", rc
    CALL ExitProcess(1)
END IF

PRINT "converted to /boot/home/eb-haiku-converted.jpg"

CALL HApplicationFree(app)
