' BMimeType - the separate meta-mime database (distinct from the
' per-file BNodeInfo type from Phase 1, node.bas). Looks up a real,
' always-installed type, lists its own registered file extensions, and
' guesses the type for a given filename.

#include once "../src/lib.bas"

DIM mt AS HMimeType
mt = HMimeTypeCreate("text/plain")

PRINT "type=", HMimeTypeType(mt)
PRINT "installed=", HMimeTypeIsInstalled(mt)

DIM descBuf(1023) AS BYTE
DIM descLen AS INTEGER
descLen = HMimeTypeGetShortDescription(mt, @descBuf(0), 1024)
IF descLen >= 0 THEN
    descBuf(descLen) = 0
    DIM descBufPtr AS ANY PTR
    descBufPtr = @descBuf(0)
    DIM descZ AS ZSTRING
    descZ = descBufPtr
    DIM descStr AS STRING
    descStr = descZ
    PRINT "short description=", descStr
END IF

DIM extMsg AS HMessage
extMsg = HMessageCreate(0)
CALL HMimeTypeGetFileExtensions(mt, extMsg)
DIM extCount AS INTEGER
extCount = HMessageCountItems(extMsg, "extensions", 0)
PRINT "registered extensions (", extCount, "):"
DIM i AS INTEGER
FOR i = 0 TO extCount - 1
    PRINT "  .", HMessageFindStringAt(extMsg, "extensions", i)
NEXT i
CALL HMessageFree(extMsg)
CALL HMimeTypeFree(mt)

' Guess the type for a few filenames.
DIM names(2) AS STRING
names(0) = "report.txt"
names(1) = "photo.png"
names(2) = "archive.zip"
FOR i = 0 TO 2
    DIM guessed AS HMimeType
    guessed = HMimeTypeCreate("")
    DIM rc AS INTEGER
    rc = HMimeTypeGuessMimeType(names(i), guessed)
    IF rc = 0 THEN
        PRINT names(i), " -> ", HMimeTypeType(guessed)
    ELSE
        PRINT names(i), " -> (no match)"
    END IF
    CALL HMimeTypeFree(guessed)
NEXT i
