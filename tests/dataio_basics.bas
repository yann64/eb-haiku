' Translation Kit extension: BMemoryIO/BMallocIO - both real
' BPositionIO subclasses, usable anywhere HFile already is. Verified
' with a real, entirely in-memory round trip: decode a real PNG file,
' Translate it (uncompressed 'bits' format) into a growing BMallocIO,
' then wrap that same buffer read-only as a BMemoryIO and decode it
' back into a fresh bitmap - confirming the bounds still match, with no
' intermediate file involved at all.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-DataIOBasicsTest")

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

' ---- BMallocIO - a real, growing in-memory destination ----

DIM mallocIO AS HMallocIO
mallocIO = HMallocIOCreate()

DIM rc AS INTEGER
rc = HTranslate(roster, stream.handle, mallocIO.handle, H_TRANSLATOR_BITMAP)
IF rc <> 0 THEN
    PRINT "FAIL: HTranslate into BMallocIO returned ", rc
    CALL ExitProcess(1)
END IF

DIM bufLen AS ULONGINT
bufLen = HMallocIOBufferLength(mallocIO)
PRINT "BMallocIO buffer length=", bufLen
IF bufLen <= 0 THEN
    PRINT "FAIL: expected a real, non-empty translated buffer"
    CALL ExitProcess(1)
END IF

CALL HBitmapStreamFree(stream) ' also frees the wrapped bitmap

' ---- BMemoryIO - wrap that same buffer read-only, decode it back ----

DIM memoryIO AS HMemoryIO
memoryIO = HMemoryIOCreateReadOnly(HMallocIOBuffer(mallocIO), bufLen)

DIM reloaded AS HBitmap
reloaded = HGetBitmap(memoryIO.handle)
IF reloaded.handle = 0 THEN
    PRINT "FAIL: HGetBitmap on the in-memory BMemoryIO buffer returned a null handle"
    CALL ExitProcess(1)
END IF

DIM bLeft AS SINGLE
DIM bTop AS SINGLE
DIM bRight AS SINGLE
DIM bBottom AS SINGLE
CALL HBitmapGetBounds(reloaded, bLeft, bTop, bRight, bBottom)
PRINT "round-trip bounds right=", bRight
PRINT "round-trip bounds bottom=", bBottom
IF bRight <> 350 OR bBottom <> 131 THEN
    PRINT "FAIL: in-memory round-trip dimensions do not match the source PNG"
    CALL ExitProcess(1)
END IF

CALL HBitmapFree(reloaded)
CALL HMemoryIOFree(memoryIO)
CALL HMallocIOFree(mallocIO)
CALL HApplicationFree(app)

PRINT "dataio basics test ok"
