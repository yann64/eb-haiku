' Storage Kit: BAppFileInfo - real executable metadata, IS-A BNodeInfo
' (already bound in Phase 1). Verified two ways: read-only against
' Tracker (a real, always-installed system app with a real, already-
' known signature - "application/x-vnd.Be-TRAK", confirmed via
' roster_clipboard_basics.bas's own earlier test), and a full write/
' read round-trip against a fresh throwaway file.

#include once "../src/lib.bas"

' ---- Read-only against a real installed app ----

DIM trackerFile AS HFile
trackerFile = HFileCreate("/boot/system/Tracker", H_READ_ONLY)
IF HFileInitCheck(trackerFile) <> 0 THEN
    PRINT "FAIL: could not open /boot/system/Tracker"
    CALL ExitProcess(1)
END IF

DIM trackerInfo AS HAppFileInfo
trackerInfo = HAppFileInfoCreate()
DIM rc AS INTEGER
rc = HAppFileInfoSetTo(trackerInfo, trackerFile)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoSetTo returned ", rc
    CALL ExitProcess(1)
END IF

DIM sigBuf(255) AS BYTE
DIM sigBufPtr AS ANY PTR
sigBufPtr = @sigBuf(0)
DIM sigLen AS INTEGER
sigLen = HAppFileInfoGetSignature(trackerInfo, sigBufPtr, 256)
IF sigLen < 0 THEN
    PRINT "FAIL: HAppFileInfoGetSignature returned ", sigLen
    CALL ExitProcess(1)
END IF
sigBuf(sigLen) = 0
DIM sigZ AS ZSTRING
sigZ = sigBufPtr
DIM sigStr AS STRING
sigStr = sigZ
PRINT "Tracker signature=", sigStr
IF sigStr <> "application/x-vnd.Be-TRAK" THEN
    PRINT "FAIL: expected Tracker's real signature"
    CALL ExitProcess(1)
END IF

DIM trackerFlags AS UINTEGER
rc = HAppFileInfoGetAppFlags(trackerInfo, trackerFlags)
PRINT "Tracker app flags rc=", rc, " flags=", trackerFlags

DIM trackerTypes AS HMessage
trackerTypes = HMessageCreate(0)
rc = HAppFileInfoGetSupportedTypes(trackerInfo, trackerTypes)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoGetSupportedTypes returned ", rc
    CALL ExitProcess(1)
END IF
DIM trackerTypeCount AS INTEGER
trackerTypeCount = HMessageCountItems(trackerTypes, "types", 0)
PRINT "Tracker supported type count=", trackerTypeCount
CALL HMessageFree(trackerTypes)

CALL HAppFileInfoFree(trackerInfo)
CALL HFileFree(trackerFile)
PRINT "read-only Tracker metadata ok"

' ---- Write/read round-trip against a fresh throwaway file ----

CONST TEST_PATH = "/boot/home/eb-haiku-appfileinfo-test.txt"
CONST TEST_SIGNATURE = "application/x-vnd.EbHaiku-AppFileInfoTest"

CALL Kill(TEST_PATH)
CALL WriteFile(TEST_PATH, "placeholder")

DIM testFile AS HFile
testFile = HFileCreate(TEST_PATH, H_READ_WRITE)
IF HFileInitCheck(testFile) <> 0 THEN
    PRINT "FAIL: could not open the throwaway test file"
    CALL ExitProcess(1)
END IF

DIM info AS HAppFileInfo
info = HAppFileInfoCreate()
rc = HAppFileInfoSetTo(info, testFile)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoSetTo (throwaway) returned ", rc
    CALL ExitProcess(1)
END IF

rc = HAppFileInfoSetSignature(info, TEST_SIGNATURE)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoSetSignature returned ", rc
    CALL ExitProcess(1)
END IF

rc = HAppFileInfoSetAppFlags(info, H_MULTIPLE_LAUNCH)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoSetAppFlags returned ", rc
    CALL ExitProcess(1)
END IF

DIM typesOut AS HMessage
typesOut = HMessageCreate(0)
CALL HMessageAddString(typesOut, "types", "text/plain")
rc = HAppFileInfoSetSupportedTypes(info, typesOut)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoSetSupportedTypes returned ", rc
    CALL ExitProcess(1)
END IF
CALL HMessageFree(typesOut)

' Read everything back to confirm the round-trip.
DIM readSigBuf(255) AS BYTE
DIM readSigBufPtr AS ANY PTR
readSigBufPtr = @readSigBuf(0)
DIM readSigLen AS INTEGER
readSigLen = HAppFileInfoGetSignature(info, readSigBufPtr, 256)
readSigBuf(readSigLen) = 0
DIM readSigZ AS ZSTRING
readSigZ = readSigBufPtr
DIM readSigStr AS STRING
readSigStr = readSigZ
PRINT "round-trip signature=", readSigStr
IF readSigStr <> TEST_SIGNATURE THEN
    PRINT "FAIL: signature round-trip mismatch"
    CALL ExitProcess(1)
END IF

DIM readFlags AS UINTEGER
rc = HAppFileInfoGetAppFlags(info, readFlags)
IF rc <> 0 OR readFlags <> H_MULTIPLE_LAUNCH THEN
    PRINT "FAIL: app flags round-trip mismatch, rc=", rc, " flags=", readFlags
    CALL ExitProcess(1)
END IF
PRINT "round-trip app flags ok"

IF HAppFileInfoIsSupportedType(info, "text/plain") <> 1 THEN
    PRINT "FAIL: IsSupportedType should be true for text/plain"
    CALL ExitProcess(1)
END IF
IF HAppFileInfoIsSupportedType(info, "image/png") <> 0 THEN
    PRINT "FAIL: IsSupportedType should be false for image/png (negative control)"
    CALL ExitProcess(1)
END IF
PRINT "IsSupportedType ok"

rc = HAppFileInfoRemoveAppFlags(info)
IF rc <> 0 THEN
    PRINT "FAIL: HAppFileInfoRemoveAppFlags returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "RemoveAppFlags ran ok"

CALL HAppFileInfoFree(info)
CALL HFileFree(testFile)
CALL Kill(TEST_PATH)

PRINT "appfileinfo basics test ok"
