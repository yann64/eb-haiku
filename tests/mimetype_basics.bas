' Storage Kit: BMimeType - the separate meta-mime database, distinct
' from the per-file BNodeInfo type already bound in Phase 1. Verified
' against "text/plain", a real type guaranteed installed on any real
' Haiku system, and against the real, installed-package-scale registry
' (492 real installed types on this host, confirmed via a standalone
' probe before writing this test - not a guessed/hardcoded count).

#include once "../src/lib.bas"

' IMPORTANT, confirmed by direct reproduction: HMimeTypeGetIcon/SetIcon
' hang indefinitely without a real BApplication existing first - the
' same "needs BApplication first" gotcha family as Translation Kit's
' GetBitmap/BClipboard::Lock (see project README's own "read this
' before" section) - construct one here even though most of this file's
' own BMimeType calls don't otherwise need it.
DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-MimeTypeBasicsTest")

DIM mt AS HMimeType
mt = HMimeTypeCreate("text/plain")

IF HMimeTypeInitCheck(mt) <> 0 THEN
    PRINT "FAIL: HMimeTypeInitCheck returned ", HMimeTypeInitCheck(mt)
    CALL ExitProcess(1)
END IF
IF HMimeTypeIsValid(mt) = 0 THEN
    PRINT "FAIL: text/plain should be a valid MIME string"
    CALL ExitProcess(1)
END IF
IF HMimeTypeIsInstalled(mt) = 0 THEN
    PRINT "FAIL: text/plain should be installed on any real Haiku system"
    CALL ExitProcess(1)
END IF
PRINT "type=", HMimeTypeType(mt)

DIM descBuf(1023) AS BYTE
DIM descLen AS INTEGER
descLen = HMimeTypeGetShortDescription(mt, @descBuf(0), 1024)
IF descLen < 0 THEN
    PRINT "FAIL: HMimeTypeGetShortDescription returned ", descLen
    CALL ExitProcess(1)
END IF
descBuf(descLen) = 0
DIM descBufPtr AS ANY PTR
descBufPtr = @descBuf(0)
DIM descZ AS ZSTRING
descZ = descBufPtr
DIM descStr AS STRING
descStr = descZ
PRINT "short description=", descStr

' ---- Real repeated-string fields - "extensions"/"applications" ----

DIM extMsg AS HMessage
extMsg = HMessageCreate(0)
DIM rc AS INTEGER
rc = HMimeTypeGetFileExtensions(mt, extMsg)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGetFileExtensions returned ", rc
    CALL ExitProcess(1)
END IF
DIM extCount AS INTEGER
extCount = HMessageCountItems(extMsg, "extensions", 0)
PRINT "text/plain extension count=", extCount
IF extCount <= 0 THEN
    PRINT "FAIL: text/plain should have at least one registered extension"
    CALL ExitProcess(1)
END IF
DIM i AS INTEGER
DIM foundTxt AS INTEGER
foundTxt = 0
FOR i = 0 TO extCount - 1
    DIM ext AS STRING
    ext = HMessageFindStringAt(extMsg, "extensions", i)
    PRINT "  extension[", i, "]=", ext
    IF ext = "txt" THEN
        foundTxt = 1
    END IF
NEXT i
IF foundTxt <> 1 THEN
    PRINT "FAIL: expected 'txt' among text/plain's own registered extensions"
    CALL ExitProcess(1)
END IF
CALL HMessageFree(extMsg)
PRINT "GetFileExtensions/HMessageCountItems/FindStringAt ok"

' ---- Real installed-type registry (492 real entries confirmed via probe) ----

DIM typesMsg AS HMessage
typesMsg = HMessageCreate(0)
rc = HMimeTypeGetInstalledTypes(typesMsg)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGetInstalledTypes returned ", rc
    CALL ExitProcess(1)
END IF
DIM typeCount AS INTEGER
typeCount = HMessageCountItems(typesMsg, "types", 0)
PRINT "installed type count=", typeCount
IF typeCount < 100 THEN
    PRINT "FAIL: expected a real, large installed-type registry (>= 100), got ", typeCount
    CALL ExitProcess(1)
END IF
DIM foundTextPlain AS INTEGER
foundTextPlain = 0
FOR i = 0 TO typeCount - 1
    DIM oneType AS STRING
    oneType = HMessageFindStringAt(typesMsg, "types", i)
    IF oneType = "text/plain" THEN
        foundTextPlain = 1
    END IF
NEXT i
IF foundTextPlain <> 1 THEN
    PRINT "FAIL: expected 'text/plain' among the real installed types"
    CALL ExitProcess(1)
END IF
CALL HMessageFree(typesMsg)
PRINT "GetInstalledTypes ok"

' ---- Real supertype registry - field name is "super_types", NOT
' "types" (a real, confirmed API inconsistency - see HMimeTypeGet-
' InstalledSupertypes's own doc comment) ----

DIM superMsg AS HMessage
superMsg = HMessageCreate(0)
rc = HMimeTypeGetInstalledSupertypes(superMsg)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGetInstalledSupertypes returned ", rc
    CALL ExitProcess(1)
END IF
DIM superCount AS INTEGER
superCount = HMessageCountItems(superMsg, "super_types", 0)
PRINT "installed supertype count=", superCount
IF superCount <= 0 THEN
    PRINT "FAIL: expected at least one real installed supertype"
    CALL ExitProcess(1)
END IF
CALL HMessageFree(superMsg)
PRINT "GetInstalledSupertypes (super_types field) ok"

' ---- GuessMimeType ----

DIM guessed AS HMimeType
guessed = HMimeTypeCreate("")
rc = HMimeTypeGuessMimeType("/boot/home/some_file.txt", guessed)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGuessMimeType returned ", rc
    CALL ExitProcess(1)
END IF
DIM guessedType AS STRING
guessedType = HMimeTypeType(guessed)
PRINT "guessed type for .txt=", guessedType
IF guessedType <> "text/plain" THEN
    PRINT "FAIL: expected text/plain guessed for a .txt file"
    CALL ExitProcess(1)
END IF
CALL HMimeTypeFree(guessed)

' ---- Icon get/set - reuses the existing HBitmap type directly.
' text/plain has a real, always-installed icon on any real Haiku
' system. ----

DIM icon AS HBitmap
icon = HBitmapCreate(0, 0, 31, 31, H_RGBA32, 0)
rc = HMimeTypeGetIcon(mt, icon, H_LARGE_ICON)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGetIcon returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "got a real large icon for text/plain ok"
CALL HBitmapFree(icon)

' Round-trip SetIcon/GetIcon on a throwaway custom type.
DIM custom AS HMimeType
custom = HMimeTypeCreate("application/x-vnd.EbHaiku-MimeTypeIconTest")
DIM setIcon AS HBitmap
setIcon = HBitmapCreate(0, 0, 15, 15, H_RGBA32, 0)
rc = HMimeTypeSetIcon(custom, setIcon, H_MINI_ICON)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeSetIcon returned ", rc
    CALL ExitProcess(1)
END IF
CALL HBitmapFree(setIcon)

DIM readBackIcon AS HBitmap
readBackIcon = HBitmapCreate(0, 0, 15, 15, H_RGBA32, 0)
rc = HMimeTypeGetIcon(custom, readBackIcon, H_MINI_ICON)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeGetIcon (round-trip) returned ", rc
    CALL ExitProcess(1)
END IF
PRINT "SetIcon/GetIcon round-trip ok"
CALL HBitmapFree(readBackIcon)
CALL HMimeTypeDelete(custom)
CALL HMimeTypeFree(custom)

' ---- Sniffer rules ----

DIM errBuf(511) AS BYTE
DIM errPtr AS ANY PTR
errPtr = @errBuf(0)
rc = HMimeTypeCheckSnifferRule("1.0 [0:3] ('PNG')", errPtr, 512)
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeCheckSnifferRule rejected a real, valid rule, rc=", rc
    CALL ExitProcess(1)
END IF
PRINT "CheckSnifferRule (valid) ok"

DIM badLen AS INTEGER
badLen = HMimeTypeCheckSnifferRule("not a valid rule at all!!", errPtr, 512)
IF badLen = 0 THEN
    PRINT "FAIL: HMimeTypeCheckSnifferRule accepted a real invalid rule"
    CALL ExitProcess(1)
END IF
errBuf(500) = 0
DIM errZ AS ZSTRING
errZ = errPtr
DIM errStr AS STRING
errStr = errZ
PRINT "CheckSnifferRule (invalid) rc=", badLen, " error=", errStr

DIM snifferType AS HMimeType
snifferType = HMimeTypeCreate("application/x-vnd.EbHaiku-SnifferRuleTest")
CALL HMimeTypeInstall(snifferType)
rc = HMimeTypeSetSnifferRule(snifferType, "1.0 [0:3] ('PNG')")
IF rc <> 0 THEN
    PRINT "FAIL: HMimeTypeSetSnifferRule returned ", rc
    CALL ExitProcess(1)
END IF

DIM ruleBuf(255) AS BYTE
DIM rulePtr AS ANY PTR
rulePtr = @ruleBuf(0)
DIM ruleLen AS INTEGER
ruleLen = HMimeTypeGetSnifferRule(snifferType, rulePtr, 256)
IF ruleLen < 0 THEN
    PRINT "FAIL: HMimeTypeGetSnifferRule returned ", ruleLen
    CALL ExitProcess(1)
END IF
ruleBuf(ruleLen) = 0
DIM ruleZ AS ZSTRING
ruleZ = rulePtr
DIM ruleStr AS STRING
ruleStr = ruleZ
PRINT "round-tripped sniffer rule=", ruleStr
IF ruleStr <> "1.0 [0:3] ('PNG')" THEN
    PRINT "FAIL: sniffer rule round-trip mismatch"
    CALL ExitProcess(1)
END IF
CALL HMimeTypeDelete(snifferType)
CALL HMimeTypeFree(snifferType)
PRINT "SetSnifferRule/GetSnifferRule round-trip ok"

CALL HMimeTypeFree(mt)
CALL HApplicationFree(app)

PRINT "mimetype basics test ok"
