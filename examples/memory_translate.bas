' BMemoryIO/BMallocIO - Translation Kit I/O entirely in memory, no
' intermediate file. Decode a real PNG, save it (uncompressed) into a
' growing BMallocIO, then decode it back from a read-only BMemoryIO
' wrapping that same buffer.

#include once "../src/lib.bas"

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MemoryTranslateExample")

DIM roster AS HTranslatorRoster
roster = HTranslatorRosterDefault()

DIM src AS HFile
src = HFileCreate("/boot/system/data/artwork/HAIKU logo - white on blue - normal.png", H_READ_ONLY)
DIM decoded AS HBitmap
decoded = HGetBitmap(src.handle)
CALL HFileFree(src)

DIM stream AS HBitmapStream
stream = HBitmapStreamCreate(decoded)

DIM mallocIO AS HMallocIO
mallocIO = HMallocIOCreate()
CALL HTranslate(roster, stream.handle, mallocIO.handle, H_TRANSLATOR_BITMAP)
PRINT "in-memory buffer length=", HMallocIOBufferLength(mallocIO)
CALL HBitmapStreamFree(stream)

DIM memoryIO AS HMemoryIO
memoryIO = HMemoryIOCreateReadOnly(HMallocIOBuffer(mallocIO), HMallocIOBufferLength(mallocIO))
DIM reloaded AS HBitmap
reloaded = HGetBitmap(memoryIO.handle)

DIM bLeft AS SINGLE
DIM bTop AS SINGLE
DIM bRight AS SINGLE
DIM bBottom AS SINGLE
CALL HBitmapGetBounds(reloaded, bLeft, bTop, bRight, bBottom)
PRINT "decoded from memory, bounds=", bRight, "x", bBottom

CALL HBitmapFree(reloaded)
CALL HMemoryIOFree(memoryIO)
CALL HMallocIOFree(mallocIO)
CALL HApplicationFree(app)
